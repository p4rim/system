"""Safe installer checks: temporary files, mocked system commands, and a PTY."""
import fcntl
import os
from pathlib import Path
import pty
import select
import shlex
import struct
import subprocess
import tempfile
import termios
import time
import unittest

INSTALLER = Path(__file__).resolve().parents[1] / "zos/install.sh"


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="zos-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.target = self.root / "target"
        (self.target / "var/log").mkdir(parents=True)
        self.script = self.root / "install.sh"
        # Redirect filesystem writes; fixture files stand in for selectable disks.
        self.script.write_text(
            INSTALLER.read_text().replace("/mnt", str(self.target))
            .replace('-b "$disk"', '-f "$disk"')
        )
        self.log = self.root / "live.log"
        self.commands = self.root / "commands"
        self.prefix = (
            f"source {shlex.quote(str(self.script))}\n"
            f"INSTALL_LOG={shlex.quote(str(self.log))}\n"
            f"CALL_LOG={shlex.quote(str(self.commands))}\n"
            "exec 3>&2\n"
        )

    def shell(self, body, answer=""):
        return subprocess.run(
            ["bash", "-c", self.prefix + body], input=answer,
            text=True, capture_output=True, timeout=10,
        )

    def test_required_failures_stay_visible(self):
        for operation, status in [("false", 1), ("exit 23", 23)]:
            with self.subTest(operation=operation):
                result = self.shell(
                    "start_installation_timer\ninitialize_progress\n"
                    "trap 'report_installation_exit \"$?\"' EXIT\n"
                    f"demo() {{ {operation}; echo UNEXPECTED; }}\n"
                    "run_step 'Demo' demo\necho COMPLETED\n"
                )
                self.assertEqual(result.returncode, status)
                self.assertIn("Installation stopped during: Demo", result.stderr)
                self.assertIn("[X] Partitioning disk", result.stderr)
                self.assertNotIn("COMPLETED", result.stdout)
                self.assertNotIn("UNEXPECTED", self.log.read_text())

    def test_optional_results_and_saved_log(self):
        for answer, status, expected in [("n", 0, "skipped"), ("y", 0, "done"), ("y", 1, "warning")]:
            with self.subTest(expected=expected):
                result = self.shell(
                    "start_installation_timer\ninitialize_progress\nCOMPLETED_STEPS=$((${#STEP_LABELS[@]} - 1))\n"
                    f"INSTALL_DOTFILES={answer}\n"
                    f"install_dotfiles() {{ echo COMMAND_NOISE; return {status}; }}\n"
                    "configure_personal_setup\nrecord_installation_duration\n"
                    "save_installation_log\nshow_completion\n"
                    'printf "STATE=%s,%s\\n" "$PERSONAL_SETUP_STATUS" "$COMPLETED_STEPS"\n'
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f"STATE={expected},14", result.stdout)
                self.assertIn("100%", result.stdout)
                self.assertNotIn("COMMAND_NOISE", result.stdout)
                self.assertEqual("needs attention" in result.stdout, expected == "warning")
                saved = self.target / "var/log/zos-install.log"
                self.assertEqual(saved.read_bytes(), self.log.read_bytes())
                self.assertEqual(saved.stat().st_mode & 0o777, 0o600)

    def test_user_setup_runs_inside_target_as_new_user(self):
        result = self.shell(r'''
ZOS_USER=tester
arch-chroot() { printf '%s\n' "$*" >> "$CALL_LOG"; }
configure_user_directories
install_rust_toolchain
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands.read_text().splitlines(), [
            f"{self.target} sudo -H -u tester env LANG=en_US.UTF-8 xdg-user-dirs-update",
            f"{self.target} sudo -H -u tester rustup default stable",
        ])
        result = self.shell(r'''
ZOS_USER=tester
start_installation_timer
initialize_progress
trap 'report_installation_exit "$?"' EXIT
arch-chroot() { return 19; }
run_step 'Installing Rust stable' install_rust_toolchain
echo UNEXPECTED_COMPLETION
''')
        self.assertEqual(result.returncode, 19)
        self.assertIn("Installation stopped during: Installing Rust stable", result.stderr)
        self.assertNotIn("UNEXPECTED_COMPLETION", result.stdout)

    def test_user_setup_runs_with_or_without_dotfiles(self):
        for choice in ("n", "y"):
            with self.subTest(dotfiles=choice):
                self.commands.unlink(missing_ok=True)
                overrides = "\n".join(
                    f"{name}() {{ :; }}" for name in [
                        "check_boot_mode", "select_target_disk", "show_installation_summary",
                        "confirm_target_disk", "partition_disk", "format_filesystems",
                        "mount_filesystems", "install_rootfs", "configure_hardware_clock",
                        "configure_accounts", "configure_git", "configure_sudo",
                        "generate_initramfs", "configure_bootloader", "generate_fstab",
                        "prompt_reboot", "install_dotfiles",
                    ]
                )
                overrides += f"\ncollect_configuration() {{ ZOS_USER=tester; INSTALL_DOTFILES={choice}; }}\n"
                overrides += r'''
initialize_installation_log() { : > "$INSTALL_LOG"; CURRENT_STEP=Starting; }
arch-chroot() { printf '%s\n' "$*" >> "$CALL_LOG"; }
main
'''
                result = self.shell(overrides)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.commands.read_text().splitlines(), [
                    f"{self.target} sudo -H -u tester env LANG=en_US.UTF-8 xdg-user-dirs-update",
                    f"{self.target} sudo -H -u tester rustup default stable",
                ])

    def test_size_validation_and_layout(self):
        result = self.shell(
            "TARGET_DISK=/dev/test\nTARGET_DISK_BYTES=8589934592\n"
            "prompt_disk_layout\nprint_partition_layout\n",
            "2\n0\n7\n1.5\n9999999999999999999\n06\n",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("size=1GiB, type=c12a", result.stdout)
        self.assertIn("size=6GiB, type=0fc6", result.stdout)
        full = self.shell("ROOT_PARTITION_SIZE=''\nprint_partition_layout\n")
        self.assertIn("\ntype=0fc6", full.stdout)

    def test_reboot_choices_and_unavailable_firmware(self):
        base = r'''
INSTALL_DURATION_SECONDS=65
PERSONAL_SETUP_STATUS=done
LOG_SAVED=yes
EFI_PART=/dev/test1
blkid() { echo 1234-abcd; }
efibootmgr() {
    if [[ "${1:-}" == --bootnext ]]; then
        printf 'bootnext %s\n' "$2" >> "$CALL_LOG"
    else
        echo 'Boot0001* Linux Boot Manager HD(1,GPT,wrong-uuid)/File(\EFI\systemd\systemd-bootx64.efi)'
        echo 'Boot000A* Linux Boot Manager HD(1,GPT,1234-ABCD)/File(\EFI\systemd\systemd-bootx64.efi)'
    fi
}
sync() { echo sync >> "$CALL_LOG"; }
mountpoint() { return 0; }
umount() { echo unmount >> "$CALL_LOG"; }
systemctl() { printf 'systemctl %s\n' "$*" >> "$CALL_LOG"; }
bootctl() { return 1; }  # supported, but not currently active
'''
        for answer, expected in [
            ("1\n", ["bootnext 000A", "sync", "unmount", "systemctl reboot"]),
            ("2\n", ["sync", "unmount", "systemctl reboot --firmware-setup"]),
            ("3\n", []),
        ]:
            with self.subTest(answer=answer):
                self.commands.unlink(missing_ok=True)
                result = self.shell(base + "prompt_reboot\n", answer)
                self.assertEqual(result.returncode, 0, result.stderr)
                calls = self.commands.read_text().splitlines() if self.commands.exists() else []
                self.assertEqual(calls, expected)
        self.commands.unlink(missing_ok=True)
        result = self.shell(base + "bootctl() { return 2; }; prompt_reboot\n", "2\n3\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unavailable on this firmware", result.stdout)
        self.assertFalse(self.commands.exists())
        result = self.shell(base + "efibootmgr() { return 1; }; prompt_reboot\n", "1\nn\n3\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Eject the ISO", result.stdout)
        self.assertFalse(self.commands.exists())

    def test_failed_unmount_prevents_reboot(self):
        result = self.shell(r'''
INSTALL_DURATION_SECONDS=0
PERSONAL_SETUP_STATUS=skipped
select_installed_boot_entry() { return 0; }
sync() { :; }
mountpoint() { return 0; }
umount() { return 1; }
systemctl() { echo UNEXPECTED_REBOOT; }
prompt_reboot
''', "1\n3\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Could not unmount", result.stdout)
        self.assertNotIn("UNEXPECTED_REBOOT", self.log.read_text())

    def test_cancelled_password_restores_echo_and_cursor(self):
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
        process = subprocess.Popen(
            ["bash", "-c", self.prefix + "initialize_ui\nui_read 'Secret: ' PASSWORD yes\necho UNEXPECTED\n"],
            stdin=slave, stdout=slave, stderr=slave,
            env=dict(os.environ, TERM="xterm-256color"), start_new_session=True,
        )
        os.close(slave)
        output = bytearray()
        try:
            deadline = time.monotonic() + 5
            while b"Secret: " not in output:
                if time.monotonic() > deadline:
                    self.fail("Password prompt did not appear")
                if select.select([master], [], [], 0.1)[0]:
                    output.extend(os.read(master, 65536))
            self.assertFalse(termios.tcgetattr(master)[3] & termios.ECHO)
            os.write(master, b"\x04")  # EOF while waiting for a password
            process.wait(timeout=5)
            while select.select([master], [], [], 0.1)[0]:
                try:
                    output.extend(os.read(master, 65536))
                except OSError:
                    break
            self.assertNotEqual(process.returncode, 0)
            self.assertTrue(termios.tcgetattr(master)[3] & termios.ECHO)
            self.assertIn(b"\033[?25h", output)
            self.assertNotIn(b"UNEXPECTED", output)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)

    def test_complete_flow_in_terminal(self):
        disk = self.root / "disk"
        disk.touch()
        # Real prompts, layout validation, runner, completion, and log persistence.
        # Only hardware-dependent operations are replaced with harmless functions.
        overrides = f'''
check_boot_mode() {{ :; }}
lsblk() {{
    if [[ "$1" == -b ]]; then echo '{disk} 34359738368 disk 0';
    else echo '32G Test VM disk'; fi
}}
partition_disk() {{ print_partition_layout; }}
configure_accounts() {{
    [[ "$ROOT_PASSWORD" == secret-root && "$USER_PASSWORD" == secret-user ]]
}}
install_dotfiles() {{ echo HIDDEN_PERSONAL_NOISE; return 1; }}
initialize_installation_log() {{
    : > "$INSTALL_LOG"
    chmod 600 "$INSTALL_LOG"
    CURRENT_STEP='Starting installation'
}}
'''
        for name in ["format_filesystems", "mount_filesystems", "install_rootfs", "configure_hardware_clock", "configure_user_directories", "install_rust_toolchain", "configure_git", "configure_sudo", "generate_initramfs", "configure_bootloader", "generate_fstab"]:
            overrides += f"{name}() {{ echo HIDDEN_COMMAND_NOISE; }}\n"
        for rows, columns in [(24, 80), (40, 100), (20, 60)]:
            with self.subTest(size=(rows, columns)):
                master, slave = pty.openpty()
                fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", rows, columns, 0, 0))
                process = subprocess.Popen(
                    ["bash", "-c", self.prefix + overrides + "main\n"],
                    stdin=slave, stdout=slave, stderr=slave,
                    env=dict(os.environ, TERM="xterm-256color"), start_new_session=True,
                )
                os.close(slave)
                output = bytearray()
                position = 0

                def respond(prompt, answer):
                    nonlocal position
                    deadline = time.monotonic() + 5
                    while prompt.encode() not in output[position:]:
                        if time.monotonic() > deadline:
                            self.fail(f"Missing prompt {prompt!r}: {output.decode(errors='replace')}")
                        if select.select([master], [], [], 0.1)[0]:
                            output.extend(os.read(master, 65536))
                    position = len(output)
                    os.write(master, (answer + "\n").encode())

                try:
                    for prompt, answer in [
                        ("Disk number:", "1"), ("Layout [1/2]:", "2"),
                        ("Root size in whole GiB:", "8"), ("Username:", "tester"),
                        ("Root password:", "secret-root"), ("Confirm password:", "secret-root"),
                        ("Password for tester:", "secret-user"), ("Confirm password:", "secret-user"),
                        ("Git user.name:", "Test User"), ("Git user.email:", "test@example.com"),
                        ("Install personal configuration?", "y"),
                        ("Erase this disk and install?", "y"),
                        ("Choose [1/2/3, default 3]:", "3"),
                    ]:
                        respond(prompt, answer)
                    process.wait(timeout=5)
                    while select.select([master], [], [], 0.1)[0]:
                        try:
                            output.extend(os.read(master, 65536))
                        except OSError:
                            break
                    text = output.decode(errors="replace")
                    self.assertEqual(process.returncode, 0, text)
                    self.assertIn("100%", text)
                    self.assertIn("Installation complete", text)
                    self.assertIn("needs attention", text)
                    self.assertIn("\033[?25h", text)
                    self.assertNotIn("secret-root", text)
                    self.assertNotIn("secret-user", text)
                    self.assertNotIn("HIDDEN_", text)
                    self.assertIn("size=8GiB", self.log.read_text())
                    if rows == 24:
                        Path("/tmp/zos-installer-terminal-preview.txt").write_text(text)
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait()
                    os.close(master)


if __name__ == "__main__":
    unittest.main(verbosity=2)

#!/usr/bin/env bash

set -euo pipefail

ZOS_ROOT="/usr/share/zos"

UI_ACTIVE=0
UI_WIDTH=72
UI_PADDING=0
UI_ROWS=24
UI_INPUT_STATE=""
COMPLETED_STEPS=0
ACTIVE_STEP_INDEX=-1
STEP_LABELS=()
STEP_STATES=()

initialize_ui() {
    exec 3>&2
    if [[ -t 0 && -t 1 && "${TERM:-dumb}" != "dumb" ]]; then
        UI_ACTIVE=1
    fi
    trap 'report_installation_exit "$?"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

refresh_ui_size() {
    local columns=80 rows=24
    if (( UI_ACTIVE )); then
        read -r rows columns < <(stty size 2>/dev/null || printf '24 80\n')
        (( rows > 0 )) || rows=24
        (( columns > 0 )) || columns=80
    fi
    UI_ROWS=$rows
    UI_WIDTH=72
    (( columns >= 76 )) || UI_WIDTH=$((columns - 4))
    (( UI_WIDTH >= 16 )) || UI_WIDTH=16
    UI_PADDING=$(((columns - UI_WIDTH) / 2))
    (( UI_PADDING >= 0 )) || UI_PADDING=0
}

ui_line() {
    local text="${1:-}"
    # Keep long paths and model names within the panel.
    if (( UI_ACTIVE && ${#text} > UI_WIDTH )); then
        text="${text:0:UI_WIDTH-3}..."
    fi
    printf '%*s%s\n' "$UI_PADDING" '' "$text"
}

ui_page() {
    local title="$1" height="${2:-18}" top index rule
    refresh_ui_size
    if (( UI_ACTIVE )); then
        printf '\033[?25h\033[2J\033[H'
        top=$(((UI_ROWS - height) / 2))
        for ((index=0; index<top; index++)); do printf '\n'; done
    fi
    printf -v rule '%*s' "$UI_WIDTH" ''
    rule="${rule// /-}"
    ui_line 'ZEN OS'
    ui_line "$rule"
    ui_line "$title"
    ui_line
}

ui_read() {
    local label="$1" destination="$2" secret="${3:-no}"
    # Disable echo before displaying the prompt, including for fast pasted input.
    if [[ "$secret" == yes ]] && (( UI_ACTIVE )); then
        UI_INPUT_STATE="$(stty -g)"
        stty -echo
    fi
    printf '%*s%s' "$UI_PADDING" '' "$label"
    if [[ "$secret" == yes ]]; then
        read -rs "$destination"
    else
        read -r "$destination"
    fi
    if [[ -n "$UI_INPUT_STATE" ]]; then
        stty "$UI_INPUT_STATE"
        UI_INPUT_STATE=""
    fi
    if [[ "$secret" == yes || ! -t 0 ]]; then printf '\n'; fi
}

restore_terminal() {
    if [[ -n "$UI_INPUT_STATE" ]]; then
        stty "$UI_INPUT_STATE" 2>/dev/null || :
        UI_INPUT_STATE=""
    fi
    if (( UI_ACTIVE )); then
        printf '\033[0m\033[?25h' >&3
    fi
}

initialize_progress() {
    STEP_LABELS=(
        'Partitioning disk' 'Formatting filesystems' 'Mounting filesystems'
        'Installing system files' 'Configuring hardware clock'
        'Configuring accounts' 'Creating user directories' 'Installing Rust stable'
        'Configuring Git' 'Configuring sudo'
        'Generating initramfs' 'Installing bootloader' 'Generating fstab'
        'Personal configuration'
    )
    STEP_STATES=()
    local label
    for label in "${STEP_LABELS[@]}"; do STEP_STATES+=(pending); done
    COMPLETED_STEPS=0
    ACTIVE_STEP_INDEX=-1
}

render_progress() {
    local total=${#STEP_LABELS[@]} percent filled empty bar index marker elapsed
    (( total > 0 )) || return 0
    ui_page 'Installing your system' "$((total + 10))"
    percent=$((COMPLETED_STEPS * 100 / total))
    filled=$((COMPLETED_STEPS * (UI_WIDTH - 9) / total))
    empty=$((UI_WIDTH - 9 - filled))
    printf -v bar '%*s' "$filled" ''
    bar="${bar// /#}"
    printf -v marker '%*s' "$empty" ''
    ui_line "[$bar$marker] $percent%"
    ui_line "$COMPLETED_STEPS of $total steps complete"
    ui_line
    if (( UI_ROWS >= total + 10 )); then
        for index in "${!STEP_LABELS[@]}"; do
            case "${STEP_STATES[$index]}" in
                pending) marker='[ ]' ;;
                running) marker='[>]' ;;
                done) marker='[OK]' ;;
                warning) marker='[!]' ;;
                skipped) marker='[-]' ;;
                failed) marker='[X]' ;;
            esac
            ui_line "$marker ${STEP_LABELS[$index]}"
        done
    else
        ui_line "${CURRENT_STEP:-Starting installation}"
    fi
    elapsed=$((SECONDS - INSTALL_STARTED_SECONDS))
    ui_line
    ui_line "Elapsed: $((elapsed / 60))m $((elapsed % 60))s"
    if (( UI_ACTIVE )); then printf '\033[?25l'; fi
}

check_boot_mode() {
    if [[ ! -d /sys/firmware/efi/efivars ]]; then
        echo "ERROR: Zen OS installer must be booted in UEFI mode"
        exit 1
    fi
}

select_target_disk() {
    local -a disks=()
    local -a sizes=()
    local disk size type readonly
    local choice index

    while read -r disk size type readonly; do
        if [[ "$type" == "disk" && "$readonly" == "0" && -b "$disk" ]]; then
            disks+=("$disk")
            sizes+=("$size")
        fi
    done < <(lsblk -b -dn -o PATH,SIZE,TYPE,RO)

    if (( ${#disks[@]} == 0 )); then
        echo "ERROR: No writable installation disks found"
        exit 1
    fi

    ui_page "Choose an installation disk" "$(( ${#disks[@]} + 9 ))"
    for index in "${!disks[@]}"; do
        ui_line "$((index + 1))) ${disks[$index]}  $(lsblk -dn -o SIZE,MODEL -- "${disks[$index]}")"
    done

    while true; do
        ui_read "Disk number: " choice
        if [[ "$choice" =~ ^[0-9]{1,6}$ ]]; then
            index=$((10#$choice - 1))
            if (( index >= 0 && index < ${#disks[@]} )); then
                TARGET_DISK="${disks[$index]}"
                TARGET_DISK_BYTES="${sizes[$index]}"
                break
            fi
        fi
        ui_line "Choose one of the listed disk numbers."
    done
}

prompt_disk_layout() {
    local choice root_gib
    # Reserve 1 GiB for EFI and 4 MiB for alignment and GPT metadata.
    local max_root_gib=$(((TARGET_DISK_BYTES - 1073741824 - 4194304) / 1073741824))

    if (( max_root_gib < 1 )); then
        echo "ERROR: Disk is too small for EFI and a root partition of at least 1 GiB"
        exit 1
    fi

    ui_page "Choose a disk layout"
    ui_line "Disk: $TARGET_DISK"
    ui_line "1) Full disk: 1 GiB EFI + root uses the remaining space"
    ui_line "2) Custom root size: 1 GiB EFI + chosen root size"
    ui_line "   Remaining space is left unallocated."
    ui_line
    ui_line "Both options erase the entire selected disk."
    ui_line

    while true; do
        ui_read "Layout [1/2]: " choice
        case "$choice" in
            1)
                DISK_LAYOUT="full"
                ROOT_PARTITION_SIZE=""
                return 0
                ;;
            2)
                DISK_LAYOUT="custom"
                break
                ;;
            *) ui_line "Choose 1 or 2." ;;
        esac
    done

    ui_page "Choose the root partition size"
    ui_line "A separate 1 GiB EFI partition is always added."
    ui_line "Maximum root size: $max_root_gib GiB"
    ui_line
    while true; do
        ui_read "Root size in whole GiB: " root_gib
        if [[ "$root_gib" =~ ^[0-9]{1,9}$ ]]; then
            root_gib=$((10#$root_gib))
            if (( root_gib >= 1 && root_gib <= max_root_gib )); then
                ROOT_PARTITION_SIZE="${root_gib}GiB"
                return 0
            fi
        fi
        ui_line "Enter a whole number from 1 to $max_root_gib."
    done
}

show_disk_layout() {
    ui_line 'EFI:        1 GiB'
    if [[ "$DISK_LAYOUT" == full ]]; then
        ui_line 'Root:       All remaining space'
    else
        ui_line "Root:       $ROOT_PARTITION_SIZE"
        ui_line 'Remainder:  Unallocated'
    fi
}

confirm_target_disk() {
    local confirm
    # Keep the summary visible while asking for the final confirmation.
    ui_line
    ui_line "WARNING: All partitions and data on $TARGET_DISK will be erased."
    ui_line 'Custom sizing does not preserve existing partitions.'
    ui_line
    ui_read 'Erase this disk and install? [y/N]: ' confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        ui_line 'Installation aborted.'
        exit 0
    fi
}

prompt_username() {
    ui_page "Create your user account"

    while true; do
        ui_read "Username: " ZOS_USER

        if [[ "$ZOS_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        fi

        ui_line "Invalid username."
        ui_line "Use lowercase letters, numbers, underscores (_), or hyphens (-)."
    done
}

prompt_password() {
    local label="$1"
    local destination="$2"
    local entered_password
    local confirmed_password

    ui_page "$label"
    ui_line "Your password is hidden while you type."
    ui_line
    while true; do
        ui_read "$label: " entered_password yes
        ui_read "Confirm password: " confirmed_password yes

        if [[ -z "$entered_password" ]]; then
            ui_line "Password cannot be empty."
            continue
        fi

        if [[ "$entered_password" != "$confirmed_password" ]]; then
            ui_line "Passwords do not match."
            continue
        fi

        printf -v "$destination" '%s' "$entered_password"
        break
    done
}

prompt_git_configuration() {
    ui_page 'Git identity'
    ui_read 'Git user.name: ' GIT_NAME
    ui_read 'Git user.email: ' GIT_EMAIL
}

prompt_personal_setup() {
    ui_page 'Personal configuration'
    ui_line 'Install your dotfiles, Oh My Zsh, and use Zsh as the default shell?'
    ui_line
    ui_read 'Install personal configuration? [y/N]: ' INSTALL_DOTFILES
}

collect_configuration() {
    prompt_disk_layout
    prompt_username
    prompt_password "Root password" ROOT_PASSWORD
    prompt_password "Password for $ZOS_USER" USER_PASSWORD
    prompt_git_configuration
    prompt_personal_setup
}

show_installation_summary() {
    ui_page 'Review your installation' 22
    ui_line "Disk:       $TARGET_DISK"
    show_disk_layout
    ui_line "Username:   $ZOS_USER"
    ui_line "Git name:   $GIT_NAME"
    ui_line "Git email:  $GIT_EMAIL"
    if [[ "$INSTALL_DOTFILES" =~ ^[Yy]$ ]]; then
        ui_line 'Personal:   Dotfiles + Oh My Zsh + Zsh'
    else
        ui_line 'Personal:   Skipped'
    fi
}

print_partition_layout() {
    printf 'label: gpt\n'
    printf 'size=1GiB, type=c12a7328-f81f-11d2-ba4b-00a0c93ec93b\n'
    printf '%stype=0fc63daf-8483-4772-8e79-3d69d8477de4\n' \
        "${ROOT_PARTITION_SIZE:+size=$ROOT_PARTITION_SIZE, }"
}

partition_disk() {
    echo "==> Partitioning $TARGET_DISK"

    # Validate the requested layout before erasing the existing partition table.
    print_partition_layout | sfdisk --no-act --wipe always "$TARGET_DISK"

    wipefs -af "$TARGET_DISK"
    print_partition_layout | sfdisk --wipe always "$TARGET_DISK"

    partprobe "$TARGET_DISK"
    udevadm settle

    if [[ "$TARGET_DISK" =~ [0-9]$ ]]; then
        EFI_PART="${TARGET_DISK}p1"
        ROOT_PART="${TARGET_DISK}p2"
    else
        EFI_PART="${TARGET_DISK}1"
        ROOT_PART="${TARGET_DISK}2"
    fi
}

format_filesystems() {
    echo "==> Formatting partitions"

    mkfs.fat -F32 "$EFI_PART"
    mkfs.ext4 -F "$ROOT_PART"
}

mount_filesystems() {
    echo "==> Mounting filesystems"

    mount "$ROOT_PART" /mnt

    mkdir -p /mnt/boot
    mount "$EFI_PART" /mnt/boot

    if ! mountpoint -q /mnt; then
        echo "ERROR: Root filesystem failed to mount"
        exit 1
    fi
    if ! mountpoint -q /mnt/boot; then
        echo "ERROR: EFI partition failed to mount"
        exit 1

    fi
}

install_rootfs() {
    echo "==> Installing prebuilt Zen OS filesystem"

    tar \
        --acls \
        --xattrs \
        --numeric-owner \
        -I zstd \
        -xf "$ZOS_ROOT/rootfs.tar.zst" \
        -C /mnt
}

configure_hardware_clock() {
    echo "==> Configuring hardware clock"

    arch-chroot /mnt hwclock --systohc
}

configure_accounts() {
    echo "==> Setting root password"

    printf 'root:%s\n' "$ROOT_PASSWORD" |
        arch-chroot /mnt chpasswd

    echo "==> Creating user $ZOS_USER"

    arch-chroot /mnt useradd \
        -m \
        -G wheel \
        -s /bin/bash \
        "$ZOS_USER"

    echo "==> Setting password for $ZOS_USER"

    printf '%s:%s\n' "$ZOS_USER" "$USER_PASSWORD" |
        arch-chroot /mnt chpasswd
}

configure_user_directories() {
    echo "==> Creating standard user directories for $ZOS_USER"

    arch-chroot /mnt \
        sudo -H -u "$ZOS_USER" \
        env LANG=en_US.UTF-8 xdg-user-dirs-update
}

install_rust_toolchain() {
    echo "==> Installing stable Rust for $ZOS_USER"

    arch-chroot /mnt \
        sudo -H -u "$ZOS_USER" \
        rustup default stable
}

configure_git() {
    echo "==> Configuring Git for $ZOS_USER"

    arch-chroot /mnt \
        sudo -H -u "$ZOS_USER" \
        git config --global user.name "$GIT_NAME"

    arch-chroot /mnt \
        sudo -H -u "$ZOS_USER" \
        git config --global user.email "$GIT_EMAIL"
}

configure_sudo() {
    echo "==> Enabling sudo for wheel group"

    cat > /mnt/etc/sudoers.d/10-wheel <<'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF

    chmod 440 /mnt/etc/sudoers.d/10-wheel

    if ! arch-chroot /mnt visudo -cf /etc/sudoers; then
        echo "ERROR: sudoers validation failed"
        exit 1
    fi
}

generate_initramfs() {
    echo "==> Generating initramfs"

    arch-chroot /mnt mkinitcpio -P
}

configure_bootloader() {
    echo "==> Installing systemd-boot"

    arch-chroot -S /mnt bootctl install

    mkdir -p /mnt/boot/loader/entries

    cat > /mnt/boot/loader/loader.conf <<'EOF'
default zos.conf
timeout 3
console-mode max
editor no
EOF

    local root_uuid
    root_uuid="$(findmnt -no UUID /mnt)"

    if [[ -z "$root_uuid" ]]; then
        echo "ERROR: Could not determine root filesystem UUID"
        exit 1
    fi

    cat > /mnt/boot/loader/entries/zos.conf <<EOF
title   Zen OS
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw
EOF
}

generate_fstab() {
    echo "==> Generating fstab"

    genfstab -U /mnt > /mnt/etc/fstab
}


install_oh_my_zsh() {
    local omz_dir="/home/$ZOS_USER/.oh-my-zsh"

    if [[ -f "/mnt$omz_dir/oh-my-zsh.sh" ]]; then
        echo "==> Oh My Zsh is already installed"
        return 0
    fi

    if [[ -e "/mnt$omz_dir" || -L "/mnt$omz_dir" ]]; then
        echo "WARNING: $omz_dir exists but has no oh-my-zsh.sh"
        return 1
    fi

    echo "==> Installing Oh My Zsh"

    if ! arch-chroot /mnt \
        sudo -H -u "$ZOS_USER" \
        git clone --depth=1 \
            https://github.com/ohmyzsh/ohmyzsh.git \
            "$omz_dir"; then
        echo "WARNING: Could not install Oh My Zsh"
        return 1
    fi
}

install_dotfiles() {
    local stow_dir="/home/$ZOS_USER/.src/stow"

    local packages=(
        bash
        foot
        ghostty
        hypr
        kitty
        nvim
        rofi
        tmux
        zsh
    )

    echo "==> Installing personal dotfiles"

    if ! arch-chroot /mnt \
        sudo -H -u "$ZOS_USER" \
        mkdir -p "/home/$ZOS_USER/.src"; then
        echo "WARNING: Could not create ~/.src"
        return 1
    fi

    if [[ -d "/mnt$stow_dir/.git" ]]; then
        echo "==> Dotfiles repository already exists, updating it"

        if ! arch-chroot /mnt \
            sudo -H -u "$ZOS_USER" \
            git -C "$stow_dir" pull --ff-only; then
            echo "WARNING: Could not update dotfiles repository"
            return 1
        fi
    else
        echo "==> Cloning dotfiles repository"

        if ! arch-chroot /mnt \
            sudo -H -u "$ZOS_USER" \
            git clone \
            https://github.com/p4rim/stow.git \
            "$stow_dir"; then
            echo "WARNING: Could not clone dotfiles repository"
            return 1
        fi
    fi

    echo "==> Checking dotfile packages"

    local package

    for package in "${packages[@]}"; do
        if [[ ! -d "/mnt$stow_dir/$package" ]]; then
            echo "WARNING: Missing Stow package: $package"
            return 1
        fi
    done

    # useradd -m copies these files from /etc/skel. Stow cannot replace
    # regular files, so preserve untouched defaults before linking ours.
    local file
    local backup_dir="/home/$ZOS_USER/.src/stow-backup-$(date +%s%N)"

    for file in .bashrc .bash_profile; do
        if [[ -f "/mnt$stow_dir/bash/$file" &&
              -f "/mnt/home/$ZOS_USER/$file" &&
              ! -L "/mnt/home/$ZOS_USER/$file" ]] &&
            cmp -s "/mnt/home/$ZOS_USER/$file" "/mnt/etc/skel/$file"; then
            if ! arch-chroot /mnt sudo -H -u "$ZOS_USER" \
                mkdir -p "$backup_dir" ||
                ! arch-chroot /mnt sudo -H -u "$ZOS_USER" \
                    mv "/home/$ZOS_USER/$file" "$backup_dir/$file"; then
                echo "WARNING: Could not back up default $file"
                return 1
            fi
            echo "==> Backed up default $file to $backup_dir/$file"
        fi
    done

    echo "==> Validating Stow operation"

    if ! arch-chroot /mnt \
        sudo -H -u "$ZOS_USER" \
        stow \
            --dir="$stow_dir" \
            --target="/home/$ZOS_USER" \
            --no-folding \
            -n \
            "${packages[@]}"; then
        echo "WARNING: Stow dry-run detected conflicts"
        return 1
    fi

    echo "==> Stowing dotfiles"

    if ! arch-chroot /mnt \
        sudo -H -u "$ZOS_USER" \
        stow \
            --dir="$stow_dir" \
            --target="/home/$ZOS_USER" \
            --no-folding \
            "${packages[@]}"; then
        echo "WARNING: Stow reported an error"
        return 1
    fi

    if ! install_oh_my_zsh; then
        return 1
    fi

    if ! arch-chroot /mnt usermod -s /bin/zsh "$ZOS_USER"; then
        echo "WARNING: Could not set Zsh as the default shell"
        return 1
    fi

    echo "==> Dotfiles installed successfully"
    return 0
}

configure_personal_setup() {
    CURRENT_STEP='Personal configuration'
    ACTIVE_STEP_INDEX=$COMPLETED_STEPS
    PERSONAL_SETUP_STATUS=skipped
    STEP_STATES[$ACTIVE_STEP_INDEX]=running
    render_progress
    printf '\n==> %s\n' "$CURRENT_STEP" >> "$INSTALL_LOG"

    if [[ ! "$INSTALL_DOTFILES" =~ ^[Yy]$ ]]; then
        printf 'Personal configuration skipped\n' >> "$INSTALL_LOG"
    elif install_dotfiles >> "$INSTALL_LOG" 2>&1; then
        PERSONAL_SETUP_STATUS=done
    else
        PERSONAL_SETUP_STATUS=warning
    fi

    STEP_STATES[$ACTIVE_STEP_INDEX]="$PERSONAL_SETUP_STATUS"
    COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
    ACTIVE_STEP_INDEX=-1
    render_progress
}

start_installation_timer() {
    INSTALL_STARTED_SECONDS=$SECONDS
}

record_installation_duration() {
    INSTALL_DURATION_SECONDS=$((SECONDS - INSTALL_STARTED_SECONDS))
    printf '\nInstallation duration: %s seconds\n' "$INSTALL_DURATION_SECONDS" >> "$INSTALL_LOG"
}

show_completion() {
    local duration
    ui_page 'Installation complete' 20
    ui_line 'Zen OS is ready.'
    if [[ "$PERSONAL_SETUP_STATUS" == warning ]]; then
        ui_line 'Personal configuration needs attention; see the log.'
    fi
    printf -v duration '%dh %02dm %02ds' \
        "$((INSTALL_DURATION_SECONDS / 3600))" \
        "$((INSTALL_DURATION_SECONDS / 60 % 60))" \
        "$((INSTALL_DURATION_SECONDS % 60))"
    ui_line "Installation time: $duration"
    ui_line "Live log: $INSTALL_LOG"
    if [[ "${LOG_SAVED:-no}" == yes ]]; then
        ui_line 'Installed log: /var/log/zos-install.log'
    else
        ui_line 'The log could not be copied to the installed system.'
    fi
    ui_line
}

initialize_installation_log() {
    exec 3>&2

    INSTALL_LOG="$(mktemp /tmp/zos-install.XXXXXX.log)"
    CURRENT_STEP="Starting installation"

    trap 'report_installation_exit "$?"' EXIT

    printf 'Zen OS installation log\n\n' >> "$INSTALL_LOG"
}

report_installation_exit() {
    local status="$1"
    restore_terminal
    if (( status != 0 )); then
        if (( ACTIVE_STEP_INDEX >= 0 )); then
            STEP_STATES[$ACTIVE_STEP_INDEX]=failed
            render_progress >&3
            restore_terminal
        fi
        printf '\nInstallation stopped during: %s\n' "${CURRENT_STEP:-Setup}" >&3
        printf 'Exit status: %s\n' "$status" >&3
        if [[ -n "${INSTALL_LOG:-}" ]]; then
            printf 'Details: %s\n' "$INSTALL_LOG" >&3
        fi
    fi
}

run_step() {
    local label="$1"
    shift
    CURRENT_STEP="$label"
    ACTIVE_STEP_INDEX=$COMPLETED_STEPS
    STEP_STATES[$ACTIVE_STEP_INDEX]=running
    render_progress
    printf '\n==> %s\n' "$label" >> "$INSTALL_LOG"

    # Keep this unconditional so errexit works inside required step functions.
    "$@" >> "$INSTALL_LOG" 2>&1

    STEP_STATES[$ACTIVE_STEP_INDEX]=done
    COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
    ACTIVE_STEP_INDEX=-1
    render_progress
}

save_installation_log() {
    LOG_SAVED=no
    if install -m 600 "$INSTALL_LOG" /mnt/var/log/zos-install.log 2>> "$INSTALL_LOG"; then
        LOG_SAVED=yes
    else
        printf 'WARNING: Could not save the installation log\n' >> "$INSTALL_LOG"
    fi
}

select_installed_boot_entry() {
    local partition_uuid boot_entries entry
    partition_uuid="$(blkid -s PARTUUID -o value "$EFI_PART")" || return 1
    [[ -n "$partition_uuid" ]] || return 1
    boot_entries="$(efibootmgr)" || return 1
    entry="$(awk -v uuid="$partition_uuid" '
        /^Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]/ &&
        index(tolower($0), tolower(uuid)) &&
        index(tolower($0), "systemd-boot") { print substr($1, 5, 4); exit }
    ' <<< "$boot_entries")"
    [[ -n "$entry" ]] || return 1
    efibootmgr --bootnext "$entry"
}

prepare_reboot() {
    sync || return 1
    if mountpoint -q /mnt; then
        umount -R /mnt || return 1
    fi
}

prompt_reboot() {
    local choice firmware_status message=''
    while true; do
        show_completion
        ui_line '1) Reboot into Zen OS'
        ui_line '2) Reboot into UEFI firmware setup'
        ui_line '3) Stay in the live environment'
        ui_line
        [[ -z "$message" ]] || ui_line "$message"
        ui_read 'Choose [1/2/3, default 3]: ' choice
        case "$choice" in
            1)
                if ! select_installed_boot_entry >> "$INSTALL_LOG" 2>&1; then
                    message='Boot entry unavailable. Eject the ISO before rebooting.'
                    # Normal reboot can still boot the disk when the ISO is removed.
                    ui_line "$message"
                    ui_read 'Reboot using firmware boot order? [y/N]: ' choice
                    [[ "$choice" =~ ^[Yy]$ ]] || continue
                fi
                if ! prepare_reboot >> "$INSTALL_LOG" 2>&1; then
                    message='Could not unmount the installed system. See the live log.'
                    continue
                fi
                restore_terminal
                if systemctl reboot >> "$INSTALL_LOG" 2>&1; then return 0; fi
                message='Reboot failed. See the live log.'
                ;;
            2)
                # Check firmware support before unmounting the installed system.
                # bootctl returns 0 for active, 1 for supported, 2 for unsupported.
                firmware_status=0
                bootctl reboot-to-firmware >> "$INSTALL_LOG" 2>&1 || firmware_status=$?
                if (( firmware_status > 1 )); then
                    message='UEFI setup reboot is unavailable on this firmware.'
                    continue
                fi
                if ! prepare_reboot >> "$INSTALL_LOG" 2>&1; then
                    message='Could not unmount the installed system. See the live log.'
                    continue
                fi
                restore_terminal
                if systemctl reboot --firmware-setup >> "$INSTALL_LOG" 2>&1; then return 0; fi
                message='UEFI setup reboot failed. See the live log.'
                ;;
            3|'')
                ui_line 'Remaining in the live environment.'
                return 0
                ;;
            *) message='Choose 1, 2, or 3.' ;;
        esac
    done
}

main() {
    initialize_ui
    check_boot_mode
    select_target_disk
    collect_configuration
    show_installation_summary
    confirm_target_disk

    start_installation_timer
    initialize_installation_log
    initialize_progress

    run_step "Partitioning disk" partition_disk
    run_step "Formatting filesystems" format_filesystems
    run_step "Mounting filesystems" mount_filesystems
    run_step "Installing system files" install_rootfs
    run_step "Configuring hardware clock" configure_hardware_clock
    run_step "Configuring accounts" configure_accounts
    run_step "Creating user directories" configure_user_directories
    run_step "Installing Rust stable" install_rust_toolchain
    run_step "Configuring Git" configure_git
    run_step "Configuring sudo" configure_sudo
    run_step "Generating initramfs" generate_initramfs
    run_step "Installing bootloader" configure_bootloader
    run_step "Generating fstab" generate_fstab

    configure_personal_setup
    record_installation_duration
    save_installation_log
    prompt_reboot
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

use std::fs;
use std::process::Command;

fn run(program: &str, args: &[&str]) -> Result<(), String> {
    let status = Command::new(program)
        .args(args)
        .status()
        .map_err(|e| format!("Failed to execute {program}: {e}"))?;

    if !status.success() {
        return Err(format!("{program} exited with status: {status}"));
    }

    Ok(())
}

fn setup() -> Result<(), String> {
    println!("Setting up Git...");

    run(
        "git",
        &["config", "--global", "init.defaultBranch", "master"],
    )?;
    run("git", &["config", "--global", "user.name", "p4rim"])?;
    run(
        "git",
        &["config", "--global", "user.email", "p4rim@proton.me"],
    )?;

    println!("Setting up standard directories...");

    run("xdg-user-dirs-update", &[])?;

    println!("Setting up Rust...");
    run("rustup", &["default", "stable"])?;
    run("rustup", &["component", "add", "rustfmt", "clippy"])?;

    println!("Setting up developmenet directories...");

    let home = std::env::var("HOME").expect("HOME environment variable is not set");

    for directory in [
        "Projects/rust",
        "Projects/c",
        "Projects/web",
        "Projects/shell",
        "Projects/experiments",
        "Projects/experiments/tmp",
    ] {
        fs::create_dir_all(format!("{home}/{directory}"))
            .map_err(|e| format!("Failed to create {directory}: {e}"))?;
    }

    println!("Checking Rust versions...");

    run("cargo", &["--version"])?;
    run("rustc", &["--version"])?;

    Ok(())
}

fn install_packages(packages: &[&str]) -> Result<(), String> {
    let mut args = vec!["-Syu", "--needed", "--noconfirm"];
    args.extend_from_slice(packages);

    run("sudo", &["-v"])?;

    let mut sudo_args = vec!["pacman"];
    sudo_args.extend_from_slice(&args);

    run("sudo", &sudo_args)
}

fn main() {
    let packages = [
        "neovim",
        "vim",
        "emacs",
        "nano",
        "zed",
        "pipewire",
        "pipewire-audio",
        "pipewire-pulse",
        "pipewire-alsa",
        "alsa-utils",
        "wiremix",
        "dbus",
        "polkit",
        "xdg-desktop-portal",
        "xdg-desktop-portal-gtk",
        "xdg-user-dirs",
        "xdg-utils",
        "qt5-wayland",
        "qt6-wayland",
        "hyprland",
        "xdg-desktop-portal-hyprland",
        "hyprland-qt-support",
        "xorg-xwayland",
        "mako",
        "rofi",
        "grim",
        "slurp",
        "swappy",
        "wl-clipboard",
        "wev",
        "wf-recorder",
        "egl-wayland",
        "zsh",
        "tmux",
        "stow",
        "zoxide",
        "btop",
        "fastfetch",
        "fzf",
        "fd",
        "ripgrep",
        "tree",
        "mpv",
        "git",
        "curl",
        "wget",
        "rsync",
        "unzip",
        "zip",
        "7zip",
        "man-db",
        "man-pages",
        "ffmpeg",
        "yt-dlp",
        "ghostty",
        "foot",
        "kitty",
        "rustup",
        "nodejs",
        "npm",
        "bun",
        "chromium",
        "firefox",
        "noto-fonts",
        "noto-fonts-cjk",
        "noto-fonts-emoji",
        "ttf-jetbrains-mono-nerd",
        "ttf-liberation-mono-nerd",
        "ttf-hack-nerd",
        "evince",
        "gnome-themes-extra",
        "dconf",
        "gsettings-desktop-schemas",
        "adwaita-icon-theme",
        "prismlauncher",
    ];

    let _ = setup();
    let _ = install_packages(&packages);
}

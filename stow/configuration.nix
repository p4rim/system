{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

    nixpkgs.config.allowUnfree = true;

  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; 

  networking.networkmanager.enable = true;
 
  time.timeZone = "Asia/Riyadh";

  i18n.defaultLocale = "en_US.UTF-8";
   console = {
     font = "Lat2-Terminus16";
     keyMap = "us";
   };

   services.gnome.gnome-keyring.enable = true;

   services.pipewire = {
     enable = true;
     pulse.enable = true;
   };

  # Users [alice] +++] 

   users.users.alice = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; 
     shell = pkgs.zsh;
   };

   programs.zsh.enable = true;

  # Programs 

	environment.systemPackages = with pkgs; [
    # Development tools 
    gcc
    git
    github-cli
		neovim 
    rustup
    nodejs
    tree-sitter
    codex

    # Terminal and command-line utilities
    ghostty
    zsh
    tmux
    stow
    zoxide
    btop
    fastfetch
    ripgrep
    tree
    curl
    wget
    rsync
    fzf

    # Archives
    unzip
    zip
    _7zz	

    # Documentation
    man-db
    man-pages


    # Desktop applications
    chromium 
    evince
    _1password-gui
    ente-auth


    # Hyprland desktop tools
		rofi 
    hyprpolkitagent
    mako
    grim
    slurp
    swappy
    wl-clipboard
    waypaper
    swaybg

    # Audio and media
    alsa-utils
    wiremix
    mpv
    ffmpeg
    yt-dlp

    # Desktop integration and supporting libraries
		dbus
		polkit
		xdg-desktop-portal
		xdg-desktop-portal-hyprland
		xdg-desktop-portal-gtk
		xdg-user-dirs
		xdg-utils
		egl-wayland
    glib
    gsettings-desktop-schemas

    # Themes and icons
    adwaita-icon-theme
    gnome-themes-extra
	];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
  ];

	fonts.packages = with pkgs; [
	  nerd-fonts.jetbrains-mono
	];

  # Nvidia 

   hardware.graphics = {
	enable = true;
	enable32Bit= true;
   };

	services.xserver.videoDrivers = [ "nvidia" ];   

	hardware.nvidia = {
		modesetting.enable = true;
		powerManagement.enable = false;
		powerManagement.finegrained = false;
		open = true;
		nvidiaSettings = true;
		package = config.boot.kernelPackages.nvidiaPackages.bleeding_edge;
	};
	
	hardware.cpu.intel.updateMicrocode = true;
	powerManagement.cpuFreqGovernor = "schedutil";

  # Hyprland 

	programs.hyprland = {
		enable = true;
		withUWSM = false;
		xwayland.enable = true;
	};

  programs.dconf.enable = true;

  # Version
  system.stateVersion = "26.05"; 
}


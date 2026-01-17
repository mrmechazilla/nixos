# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  #############################################################################
  # IMPORTS
  #############################################################################

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  #############################################################################
  # BOOT CONFIGURATION
  #############################################################################

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #############################################################################
  # NETWORKING
  #############################################################################

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  #############################################################################
  # LOCALIZATION
  #############################################################################

  # Set your time zone.
  time.timeZone = "Africa/Casablanca";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ar_MA.UTF-8";
    LC_IDENTIFICATION = "ar_MA.UTF-8";
    LC_MEASUREMENT = "ar_MA.UTF-8";
    LC_MONETARY = "ar_MA.UTF-8";
    LC_NAME = "ar_MA.UTF-8";
    LC_NUMERIC = "ar_MA.UTF-8";
    LC_PAPER = "ar_MA.UTF-8";
    LC_TELEPHONE = "ar_MA.UTF-8";
    LC_TIME = "ar_MA.UTF-8";
  };

  #############################################################################
  # DESKTOP ENVIRONMENT (GNOME)
  #############################################################################

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.desktopManager.gnome.enable = true;

  # Enable dark theme for GNOME
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.interface]
    color-scheme='prefer-dark'
    gtk-theme='Adwaita-dark'
  '';
  services.desktopManager.gnome.extraGSettingsOverridePackages = [
    pkgs.gsettings-desktop-schemas
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "azerty";
  };

  #############################################################################
  # HARDWARE & PERIPHERALS
  ############################################################################

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  #############################################################################
  # NVIDIA GRAPHICS
  #############################################################################
  
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;

    # Prefer proprietary kernel module for GTX 1650 laptops (lowest risk)
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      
      # Fill these from: lspci | grep -E "VGA|3D"
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  #############################################################################
  # USER ACCOUNTS
  #############################################################################

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.youssef = {
    isNormalUser = true;
    description = "youssef";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [
      # User-specific packages
    ];
  };

  #############################################################################
  # STORAGE OPTIMIZATION
  #############################################################################

  # Enable TRIM for SSD (works with BTRFS)
  services.fstrim.enable = true;

  #############################################################################
  # FLATPAK (SANDBOXED DESKTOP APPS)
  #############################################################################

  services.flatpak.enable = true;

  systemd.user.services.flatpak-setup = {
    description = "Setup Flathub and install Flatpak apps (user session)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
    };

    path = [ pkgs.flatpak ];

    script = ''
      set -euo pipefail

      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

      apps=(
        "it.mijorus.gearlever"
      )

      for app in "''${apps[@]}"; do
        flatpak install -y --noninteractive flathub "$app" || true
      done
    '';
  };

  systemd.user.timers.flatpak-setup = {
    description = "Run Flatpak setup shortly after login";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "2m";
      Persistent = true;
    };
  };

  #############################################################################
  # NIX CONFIGURATION
  #############################################################################

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  #############################################################################
  # PERFORMANCE OPTIMIZATIONS
  #############################################################################

  # Faster boot - disable NetworkManager wait online
  systemd.services.NetworkManager-wait-online.enable = false;

  #############################################################################
  # APPIMAGE SUPPORT
  #############################################################################
 
  # Enable AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;  # Allow running AppImages directly
  };

  #############################################################################
  # VIRTUALIZATION (QEMU/KVM + Virt-Manager)
  #############################################################################
  
  virtualisation.docker.enable = true;
  # optional but common:
  virtualisation.docker.enableOnBoot = true;

  #############################################################################
  # SYSTEM PACKAGES
  #############################################################################

  programs.java = {
    enable = true;
    package = pkgs.jdk21_headless;
  };  

  environment.systemPackages = with pkgs; [
     brave
     obsidian
     spotify
     google-chrome

  # GNOME apps (preload commonly used apps)
    gnome-console
    gnome-text-editor
    gnome-calculator
    gnome-system-monitor
    gnome-tweaks
    gnomeExtensions.ddterm
    gnomeExtensions.clipboard-history
    gnomeExtensions.vitals
    gnomeExtensions.caffeine
    gnomeExtensions.dash-to-panel
    gnomeExtensions.blur-my-shell
  
  # Development Tools (Nodejs, )
    nodejs_24
    jdk21_headless
    maven
    vscode
    bruno
    jetbrains.idea
   
    # System tools
    wget
    git
    docker-compose
    emacs
    appimage-run  # Tool to run AppImages
    neofetch 
  ];

  #############################################################################
  # OPTIONAL CONFIGURATIONS (COMMENTED OUT)
  #############################################################################

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}

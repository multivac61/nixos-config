# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, lib, user, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/shared/home-manager.nix
      ../../modules/shared
      ../../modules/shared/cachix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Emulate arm64 binaries
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "gdrn"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # TODO: Do we need all these interfaces to WoL?
  networking.interfaces.enp11s0.wakeOnLan.enable = true; # 74:56:3c:3d:d8:82 1Gbps
  networking.interfaces.enp10s0.wakeOnLan.enable = true; # 98:b7:85:1e:f6:4f 10Gbps

  # Set your time zone.
  time.timeZone = "Atlantic/Reykjavik";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "is_IS.UTF-8";
    LC_IDENTIFICATION = "is_IS.UTF-8";
    LC_MEASUREMENT = "is_IS.UTF-8";
    LC_MONETARY = "is_IS.UTF-8";
    LC_NAME = "is_IS.UTF-8";
    LC_NUMERIC = "is_IS.UTF-8";
    LC_PAPER = "is_IS.UTF-8";
    LC_TELEPHONE = "is_IS.UTF-8";
    LC_TIME = "is_IS.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable te GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;

  # System is a server, don't let it sleep
  services.xserver.displayManager.gdm.autoSuspend = false;
  services.xserver.displayManager.gdm.settings = {
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = 0;
      sleep-inactive-battery-timeout = 0;
    };
  };
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user} = {
    isNormalUser = true;
    description = "${user}";
    extraGroups = [ "networkmanager" "wheel" "docker" "plugdev" ];
  };

  nix.settings.trusted-users = [ "root" "@wheel" "${user}" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Place GitHub Access token under ~/.config/nix/nix.conf: access-tokens = github.com=***censored***
  nix.settings.experimental-features = lib.mkDefault "nix-command flakes";

  virtualisation.docker.enable = true;
  virtualisation.multipass.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ 8080 ];

  # Enable tailscale. We manually authenticate when we want with "sudo tailscale up". 
  # If you don't use tailscale, you should comment out or delete all of this.
  services.tailscale.enable = true;

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
  system.stateVersion = "23.05"; # Did you read the comment?
}

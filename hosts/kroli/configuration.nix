{
  inputs,
  pkgs,
  flake,
  ...
}:
{
  imports = [
    ./disk-config.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.mixins-systemd-boot
    inputs.srvos.nixosModules.mixins-terminfo
    inputs.srvos.nixosModules.mixins-nix-experimental
    inputs.srvos.nixosModules.mixins-trusted-nix-caches
    inputs.disko.nixosModules.disko
    flake.modules.shared.default
    flake.modules.shared.home-manager
    flake.nixosModules.common
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.05";

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [ "kvm-intel" ];
  };

  networking.hostName = "kroli";

  users.users.genki = {
    isNormalUser = true;
    shell = pkgs.fish;
    openssh.authorizedKeys.keyFiles = [ ../../authorized_keys ];
    extraGroups = [ "wheel" ];
    hashedPassword = "";
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [ ../../authorized_keys ];
  users.users.root.hashedPassword = "";
}

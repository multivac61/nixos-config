{ pkgs, user, ... }:

{
  imports = [
    ../shared/home-manager.nix
  ];

  users.users.${user} = {
    name = "${user}";
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqWL96+z6Wk2IgF6XRyoZAVUXmCmP8I78dUpA4Qy4bh genki@gdrn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ1uxevLNJOPIPRMh9G9fFSqLtYjK5R7+nRdtsas2KwX"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbdC7LjlCTSRadDqz5UIeCBsvekpoN2vMXUrl8R58Vf daniel@genkiinstruments.com"
    ];
  };

  # Since we're using fish as our shell
  programs.fish.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users.${user} = { ... }:
      {
        home.enableNixpkgsReleaseCheck = false;
        home.stateVersion = "23.05";
        xdg.enable = true; # Needed for fish interactiveShellInit hack
      };
  };
}

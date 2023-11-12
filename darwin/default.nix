{ pkgs, lib, ... }:

let user = "olafur"; in
{

  imports = [
    ./home-manager.nix
    ../shared
    ../shared/cachix
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Setup user, packages, programs
  nix = {
    package = pkgs.nixUnstable;
    settings.trusted-users = [ "@admin" "${user}" ];

    gc = {
      user = "root";
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Load configuration that is shared across systems
  environment.systemPackages = (import ../shared/packages.nix { inherit pkgs; });

  

  # Enable fonts dir
  fonts.fontDir.enable = true;

  system = {
    stateVersion = 4;

    defaults = {
      LaunchServices = {
        LSQuarantine = false;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = false;
        launchanim = false;
        orientation = "left";
        tilesize = 48;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    activationScripts.postActivation.text = ''
        # Set the default shell as fish for the user
        sudo chsh -s ${lib.getBin pkgs.fish}/bin/fish "${user}"
      '';

    # see https://github.com/LnL7/nix-darwin/issues/122
    environment.etc."fish/nixos-env-preinit.fish".text = lib.mkMerge [
      (lib.mkBefore ''
    set -g __nixos_path_original $PATH
        '')
      (lib.mkAfter ''
    function __nixos_path_fix -d "fix PATH value"
    set -l result (string replace '$HOME' "$HOME" $__nixos_path_original)
    for elt in $PATH
      if not contains -- $elt $result
        set -a result $elt
      end
    end
    set -g PATH $result
    end
    '')
    ];
  };
}

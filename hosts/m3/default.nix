{ config, ... }:
{
  # Enable tailscale. We manually authenticate when we want with `tailscale up`
  services.tailscale.enable = true;

  # Auto upgrade nix package and the daemon service (multi-user install, aborting activation
  services.nix-daemon.enable = true;

  homebrew = {
    enable = true;
    casks = [
      "shortcat"
      "raycast"
      "arc"
      "karabiner-elements"
      {
        name = "nikitabobko/tap/aerospace";
        args = {
          no_quarantine = true;
        };
      }
      # "znotch"
      {
        name = "zkondor/dist/znotch";
        # args = {
        #   no_quarantine = true;
        # };
      }
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    masApps = {
      # `nix run nixpkgs#mas -- search <app name>`
      "Keynote" = 409183694;
      "ColorSlurp" = 1287239339;
      "Numbers" = 409203825;
    };
  };

  system = {
    stateVersion = 4;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = false;
        tilesize = 72;
        orientation = "left";
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
      # normal minimum is 15 (225 ms)\ defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
      defaults write -g InitialKeyRepeat -int 10
      defaults write -g KeyRepeat -int 1
    '';
  };
}

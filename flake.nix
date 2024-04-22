{
  description = "Nix runs my 🌍🌎🌏";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, nixos-hardware, nix-index-database, nixos-wsl } @inputs:
    let
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      devShell = system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = with pkgs; mkShell {
            nativeBuildInputs = [ bashInteractive git ];
            shellHook = ''export EDITOR=nvim'';
          };
        };
      mkApp = scriptName: host: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          HOST="${host}" ${self}/apps/${system}/${scriptName}
        '')}/bin/${scriptName}";
      };
      mkLinuxApps = system: {
        "gdrn" = mkApp "build-switch" "gdrn" system;
      };
      mkDarwinApps = system: {
        "m3" = mkApp "build-switch" "m3" system;
        "d" = mkApp "build-switch" "d" system;
        "gkr" = mkApp "build-switch" "gkr" system;
      };
    in
    rec {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      darwinConfigurations =
        {
          m3 =
            let
              name = "Ólafur Bjarki Bogason";
              user = "olafur";
              email = "olafur@genkiinstruments.com";
            in
            darwin.lib.darwinSystem
              {
                system = "aarch64-darwin";
                specialArgs = { inherit inputs user name email; };
                modules = [
                  home-manager.darwinModules.home-manager
                  nix-homebrew.darwinModules.nix-homebrew
                  {
                    nix-homebrew = {
                      enable = true;
                      inherit user;
                      taps = {
                        "homebrew/homebrew-core" = homebrew-core;
                        "homebrew/homebrew-cask" = homebrew-cask;
                        "homebrew/homebrew-bundle" = homebrew-bundle;
                      };
                      mutableTaps = false;
                      autoMigrate = true;
                    };
                  }
                  ./hosts/m3
                ];
              };
          gkr =
            let
              name = "Genki";
              user = "genki";
              email = "olafur@genkiinstruments.com";
              host = "gkr";
            in
            darwin.lib.darwinSystem
              {
                system = "aarch64-darwin";
                specialArgs = { inherit inputs user name email host; };
                modules = [
                  home-manager.darwinModules.home-manager
                  nix-homebrew.darwinModules.nix-homebrew
                  {
                    nix-homebrew = {
                      enable = true;
                      inherit user;
                      taps = {
                        "homebrew/homebrew-core" = homebrew-core;
                        "homebrew/homebrew-cask" = homebrew-cask;
                        "homebrew/homebrew-bundle" = homebrew-bundle;
                      };
                      mutableTaps = false;
                      autoMigrate = true;
                    };
                  }
                  ./hosts/gkr
                ];
              };
          d =
            let
              name = "Daniel Gretarsson";
              user = "genki";
              email = "daniel@genkiinstruments.com";
              host = "d";
            in
            darwin.lib.darwinSystem
              {
                system = "aarch64-darwin";
                specialArgs = { inherit inputs user name email host; };
                modules = [
                  home-manager.darwinModules.home-manager
                  nix-homebrew.darwinModules.nix-homebrew
                  {
                    nix-homebrew = {
                      enable = true;
                      inherit user;
                      taps = {
                        "homebrew/homebrew-core" = homebrew-core;
                        "homebrew/homebrew-cask" = homebrew-cask;
                        "homebrew/homebrew-bundle" = homebrew-bundle;
                      };
                      mutableTaps = false;
                      autoMigrate = true;
                    };
                  }
                  ./hosts/d
                ];
              };
        };

      nixosConfigurations = {
        gdrn =
          let
            name = "Ólafur Bjarki Bogason";
            user = "genki";
            email = "olafur@genkiinstruments.com";
          in
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs user name email; };
            modules = [
              home-manager.nixosModules.home-manager
              ./hosts/gdrn
            ];
          };
        nix-deployment =
          let
            name = "Ólafur Bjarki Bogason";
            user = "genki";
            host = "nix-deployment";
            email = "olafur@genkiinstruments.com";
          in
          nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = { inherit inputs user host name email; };
            modules = [
              nixos-hardware.nixosModules.raspberry-pi-4
              home-manager.nixosModules.home-manager
              "${nixpkgs}/nixos/modules/profiles/minimal.nix"
              ./hosts/nix-deployment/configuration.nix
            ];
          };
        jfdr =
          let
            name = "Ólafur Bjarki Bogason";
            user = "genki";
            host = "jfdr";
            email = "olafur@genkiinstruments.com";
            isWSL = true;
          in
          nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = { inherit inputs user host name email isWSL; };
            modules = [
              nixos-wsl.nixosModules.wsl
              home-manager.nixosModules.home-manager
              ./hosts/gdrn
            ];
          };
      };

      images = {
        nix-deployment = (self.nixosConfigurations.nix-deployment.extendModules {
          modules = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            {
              disabledModules = [ "profiles/base.nix" ];
              sdImage.compressImage = false;
            }
          ];
        }).config.system.build.sdImage;
      };
      packages.x86_64-linux.nix-deployment-image = images.nix-deployment;
      packages.aarch64-linux.nix-deployment-image = images.nix-deployment;
    };
}

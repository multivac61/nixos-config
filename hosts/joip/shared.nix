{ inputs, pkgs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };
  };

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions =
      let
        empty_registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}'';
      in
      ''
        experimental-features = nix-command flakes ca-derivations impure-derivations recursive-nix
        flake-registry = ${empty_registry}
        builders-use-substitutes = true
      '';
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}

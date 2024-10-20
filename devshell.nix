{ pkgs, perSystem }:
pkgs.mkShell {
  packages =
    with pkgs;
    [
      bashInteractive
      git
      nixos-anywhere
      age
      age-plugin-yubikey
      age-plugin-fido2-hmac
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      perSystem.nix-darwin.darwin-rebuild
    ];

  env = { };

  shellHook = ''export EDITOR=nvim'';
}

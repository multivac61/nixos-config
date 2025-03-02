{
  inputs,
  flake,
  config,
  ...
}:
{
  imports = [
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.mixins-systemd-boot
    inputs.srvos.nixosModules.mixins-terminfo
    inputs.srvos.nixosModules.mixins-trusted-nix-caches
    inputs.disko.nixosModules.disko
    inputs.agenix.nixosModules.default
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.buildbot-nix.nixosModules.buildbot-master
    inputs.buildbot-nix.nixosModules.buildbot-worker
    flake.modules.shared.default
    flake.nixosModules.common
    ./disko.nix
  ];

  networking.hostName = "x";

  facter.reportPath = ./facter.json;

  users.users.root.openssh.authorizedKeys.keyFiles = [ "${flake}/authorized_keys" ];

  # [TODO]: Provide upstream fix? (March 02, 2025 17:25, )
  users.groups.secrets = {
    members = [
      "oauth2-proxy"
      "buildbot"
    ];
  };

  age.secrets = {
    buildbot-github-app-secret-key.file = "${inputs.secrets}/buildbot-github-app-secret-key.age";
    buildbot-github-oauth-secret.file = "${inputs.secrets}/buildbot-github-oauth-secret.age";
    buildbot-github-webhook-secret.file = "${inputs.secrets}/buildbot-github-webhook-secret.age";
    buildbot-nix-worker-password.file = "${inputs.secrets}/buildbot-nix-worker-password.age";
    buildbot-nix-workers-json.file = "${inputs.secrets}/buildbot-nix-workers-json.age";

    buildbot-client-secret = {
      file = "${inputs.secrets}/buildbot-client-secret.age";
      owner = "root";
      group = "secrets";
      mode = "0440";
    };

    buildbot-github-cookie-secret = {
      file = "${inputs.secrets}/buildbot-github-cookie-secret.age";
      owner = "root";
      group = "secrets";
      mode = "0440";
    };

    buildbot-http-basic-auth-password = {
      file = "${inputs.secrets}/buildbot-http-basic-auth-password.age";
      owner = "root";
      group = "secrets";
      mode = "0440";
    };
  };

  services.buildbot-nix.master = {
    enable = true;
    domain = "buildbot.bygenki.com";
    outputsPath = "/var/www/buildbot/nix-outputs/";
    workersFile = config.age.secrets.buildbot-nix-workers-json.path;
    admins = [
      "multivac61"
      "dingari"
      "MatthewCroughan"
    ];
    authBackend = "httpbasicauth";
    # this is a randomly generated secret, which is only used to authenticate requests from the oauth2 proxy to buildbot
    httpBasicAuthPasswordFile = config.age.secrets.buildbot-http-basic-auth-password.path;
    github = {
      enable = true;
      webhookSecretFile = config.age.secrets.buildbot-github-webhook-secret.path;
      oauthId = "Ov23liztqfvRnVaEz57V";
      oauthSecretFile = config.age.secrets.buildbot-github-oauth-secret.path;
      topic = "build-with-buildbot";
      authType.app = {
        secretKeyFile = config.age.secrets.buildbot-github-app-secret-key.path;
        id = 1163488;
      };
    };
    accessMode.fullyPrivate = {
      backend = "github";
      # this is a randomly generated alphanumeric secret, which is used to encrypt the cookies set by oauth2-proxy, it must be 8, 16, or 32 characters long
      cookieSecretFile = config.age.secrets.buildbot-github-cookie-secret.path;
      clientSecretFile = config.age.secrets.buildbot-client-secret.path;
      clientId = "Iv23lioyXvbIN5gVi6KN";
    };
  };

  services.buildbot-nix.worker = {
    enable = true;
    workerPasswordFile = config.age.secrets.buildbot-nix-worker-password.path;
  };

  services.nginx.virtualHosts.${config.services.buildbot-nix.master.domain} = {
    forceSSL = true;
    enableACME = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "olafur@genkiinstruments.com";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 90;
  };

  nix.sshServe = {
    protocol = "ssh-ng";
    enable = true;
    write = true;
    # For Nix remote builds, the SSH authentication needs to be non-interactive and not dependent on ssh-agent, since the Nix daemon needs to be able to authenticate automatically.
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMSR/8/YBvhetwK3qcgnz39xnk27Oq1mHLaEpFRiXhR olafur@M3.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgZsVoqTNrbGtewP2+mEBSXQuiEEWcGuRyp0VtyQ9NR genki@v1"
    ];
  };
  nix.settings.trusted-users = [
    "nix-ssh"
    "@wheel"
  ];

  system.stateVersion = "24.11";
}

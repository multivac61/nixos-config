{ pkgs, lib, ... }:
let
  addresses = {
    prowlarr = "192.168.100.11:9696";
    sonarr = "192.168.100.12:8989";
    sabnzbd = "192.168.100.13:8080";
    radarr = "192.168.100.14:7878";
    jellyfin = "192.168.100.15:8096";
    plex = "192.168.100.16:32400";
    bazarr = "192.168.100.17:6767";
    jellyseerr = "192.168.100.18:5055";
  };

  libx = import ./lib.nix { inherit pkgs lib addresses; };
in
{
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "eno1";
  };

  containers = {
    jellyfin = libx.mkAppContainer { name = "jellyfin"; };
    prowlarr = libx.mkAppContainer { name = "prowlarr"; };
    radarr = libx.mkAppContainer { name = "radarr"; };
    sabnzbd = libx.mkAppContainer { name = "sabnzbd"; };
    sonarr = libx.mkAppContainer { name = "sonarr"; };
    plex = libx.mkAppContainer { name = "plex"; };
    bazarr = libx.mkAppContainer { name = "bazarr"; };
    jellyseerr = libx.mkAppContainer { name = "jellyseerr"; };
  };
}

{ config, lib, hostVars, ... }:
{
  imports = [
    ../../modules/profiles/desktop-hyprland.nix
    ../../modules/profiles/desktop-gnome.nix
    ../../modules/profiles/gaming.nix
    ../../modules/profiles/networking.nix
    ../../modules/profiles/ai-server.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  services.greetd.enable = lib.mkForce false;

  users.users.mfo = {
    isNormalUser = true;
    description = "Mickaël Folio";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    hashedPasswordFile = config.sops.secrets."ms-s1-max/users/mfo-password-hash".path;
  };

  users.users.dfo = {
    isNormalUser = true;
    description = "Delphine Folio";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    hashedPasswordFile = config.sops.secrets."ms-s1-max/users/dfo-password-hash".path;
  };

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../secrets/hosts/ms-s1-max.yaml;
  };

  sops.secrets = {
    "ms-s1-max/bootstrap/mfo-password" = {
      key = "hosts.ms-s1-max.users.mfo.bootstrapPassword";
      mode = "0400";
    };
    "ms-s1-max/bootstrap/dfo-password" = {
      key = "hosts.ms-s1-max.users.dfo.bootstrapPassword";
      mode = "0400";
    };
    "ms-s1-max/users/mfo-password-hash" = {
      key = "hosts.ms-s1-max.users.mfo.passwordHash";
      neededForUsers = true;
    };
    "ms-s1-max/users/dfo-password-hash" = {
      key = "hosts.ms-s1-max.users.dfo.passwordHash";
      neededForUsers = true;
    };
  };

  warnings = [
    "NordVPN is part of the conceptual target capability for ms-s1-max, but nixpkgs unstable does not provide an official supported NordVPN package/module. Keep this capability documented until upstream support exists."
  ];
}

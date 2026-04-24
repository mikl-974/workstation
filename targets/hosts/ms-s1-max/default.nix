{ config, lib, hostVars, ... }:
{
  imports = [
    ../../modules/profiles/desktop-hyprland.nix
    ../../modules/profiles/desktop-gnome.nix
    ../../modules/profiles/gaming.nix
    ../../modules/profiles/networking.nix
    ../../modules/profiles/ai-server.nix
    ../../modules/security/ssh.nix
    ../../modules/users/mfo.nix
    ../../modules/users/dfo.nix
    ../../modules/users/root.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  services.greetd.enable = lib.mkForce false;

  # SSH key-only — mfo's pubkey comes from modules/users/mfo.nix.
  infra.security.ssh.enable = true;

  # Per-host sops password overrides — base user attrs come from modules/users/mfo.nix and dfo.nix.
  users.users.mfo.hashedPasswordFile = config.sops.secrets."ms-s1-max/users/mfo-password-hash".path;
  users.users.dfo.hashedPasswordFile = config.sops.secrets."ms-s1-max/users/dfo-password-hash".path;

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../secrets/hosts/ms-s1-max.yaml;
  };

  infra.users.root = {
    enable = true;
    sopsFile = ../../../secrets/common.yaml;
  };

  sops.secrets = {
    "ms-s1-max/users/mfo-password-hash" = {
      key            = "hosts.ms-s1-max.users.mfo.passwordHash";
      neededForUsers = true;
    };
    "ms-s1-max/users/dfo-password-hash" = {
      key            = "hosts.ms-s1-max.users.dfo.passwordHash";
      neededForUsers = true;
    };
  };

  warnings = [
    "NordVPN is part of the conceptual target capability for ms-s1-max, but nixpkgs unstable does not provide an official supported NordVPN package/module. Keep this capability documented until upstream support exists."
  ];
}

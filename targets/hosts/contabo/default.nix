# NixOS configuration for the Contabo VPS (`contabo`).
#
# Composition:
# - `modules/profiles/server.nix` provides the hardened server baseline
#   (sudo, SSH, firewall + tailscale0 trust, Tailscale, generic admin user).
# - `modules/dokploy` activates the Docker engine and opens 80/443 so Dokploy
#   can operate workloads. Dokploy itself runs outside of Nix.
# - `disko.nix` describes a simple GPT/EFI/ext4 layout for the VPS root disk.
{ config, hostVars, lib, ... }:
{
  imports = [
    ../../../modules/profiles/server.nix
    ../../../modules/users/root.nix
    ../../../modules/dokploy
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = lib.mkDefault hostVars.timezone;
  i18n.defaultLocale = lib.mkDefault hostVars.locale;
  system.stateVersion = lib.mkDefault "24.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../secrets/hosts/contabo.yaml;
  };

  infra.users.admin.hashedPasswordFile =
    config.sops.secrets."contabo/users/admin-password-hash".path;
  infra.users.admin.sshAuthorizedKeys = (import ../../../modules/users/authorized-keys.nix).mfo;

  infra.users.root = {
    enable = true;
    sopsFile = ../../../secrets/common.yaml;
  };

  sops.secrets."contabo/users/admin-password-hash" = {
    key = "hosts/contabo/users/admin/passwordHash";
    neededForUsers = true;
  };

  infra.dokploy.enable = true;
}

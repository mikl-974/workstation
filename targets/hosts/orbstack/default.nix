# NixOS configuration for the `orbstack` developer VM.
#
# OrbStack provisions a clean NixOS install (its own disk layout, its own
# /etc/nixos/hardware-configuration.nix). This host therefore:
#   - does NOT carry a disko.nix
#   - does NOT define a bootloader (OrbStack handles boot)
#   - does NOT pin fileSystems (inherited from the running system)
#
# The full system is brought up with:
#   sudo nixos-rebuild switch --flake .#orbstack
#
# It mirrors `sandbox` semantically (server profile + admin user via sops),
# but with mfo as the operator account so the developer logs in directly.
{ config, hostVars, lib, pkgs, ... }:
{
  imports = [
    ../../../modules/profiles/server.nix
    ../../../modules/profiles/virtual-machine.nix
    ../../../modules/users/mfo.nix
    ../../../modules/users/root.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone       = lib.mkDefault hostVars.timezone;
  i18n.defaultLocale  = lib.mkDefault hostVars.locale;
  system.stateVersion = lib.mkDefault "24.11";

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../secrets/hosts/orbstack.yaml;
  };

  infra.users.root = {
    enable = true;
    sopsFile = ../../../secrets/common.yaml;
  };

  sops.secrets."orbstack/users/mfo-password-hash" = {
    key = "hosts/orbstack/users/mfo/passwordHash";
    neededForUsers = true;
  };

  users.users.mfo.hashedPasswordFile =
    config.sops.secrets."orbstack/users/mfo-password-hash".path;

  # Cloud-init: provisions SSH keys, the sops age key, the repo clone, and the
  # initial nixos-rebuild at first boot. Kept enabled afterwards so re-creating
  # the VM with the same user-data is idempotent.
  services.cloud-init = {
    enable = true;
    network.enable = false;   # OrbStack handles networking natively
  };
  # cloud-init needs git on PATH to clone the infra repo at first boot.
  environment.systemPackages = [ pkgs.git ];
}

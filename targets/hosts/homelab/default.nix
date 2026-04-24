# NixOS configuration for the `homelab` VM.
#
# Composition:
# - `modules/profiles/server.nix` provides the hardened baseline
#   (sudo, SSH key-only, firewall + tailscale0, Tailscale, admin user).
# - `modules/users/root.nix` — enable once secrets/hosts/homelab.yaml
#   contains the `root.passwordHash` key (see module for instructions).
# - `disko.nix` — GPT/EFI/ext4 layout for the virtio block device.
#
# Service stacks are assigned via deployments/inventory.nix.
{ config, hostVars, lib, ... }:
{
  imports = [
    ../../../modules/profiles/server.nix
    ../../../modules/users/root.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone       = lib.mkDefault hostVars.timezone;
  i18n.defaultLocale  = lib.mkDefault hostVars.locale;
  system.stateVersion = "24.11";

  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../secrets/hosts/homelab.yaml;
  };

  infra.users.admin.hashedPasswordFile =
    config.sops.secrets."homelab/users/admin-password-hash".path;
  infra.users.admin.sshAuthorizedKeys = (import ../../../modules/users/authorized-keys.nix).mfo;

  infra.users.root = {
    enable = true;
    sopsFile = ../../../secrets/common.yaml;
  };

  sops.secrets."homelab/users/admin-password-hash" = {
    key = "hosts.homelab.users.admin.passwordHash";
    neededForUsers = true;
  };
}

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
{ hostVars, lib, ... }:
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

  # Uncomment after creating secrets/hosts/homelab.yaml with root.passwordHash:
  # infra.security.sops = {
  #   enable          = true;
  #   defaultSopsFile = ../../../secrets/hosts/homelab.yaml;
  # };
  # infra.users.root = {
  #   enable   = true;
  #   sopsFile = ../../../secrets/hosts/homelab.yaml;
  # };
}

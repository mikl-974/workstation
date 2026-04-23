# NixOS configuration for the `sandbox` VM.
#
# Composition:
# - `modules/profiles/server.nix` provides the hardened baseline
#   (sudo, SSH key-only, firewall + tailscale0, Tailscale, admin user).
# - `modules/users/root.nix` — enable once secrets/hosts/sandbox.yaml
#   contains the `root.passwordHash` key (see module for instructions).
# - `disko.nix` — GPT/EFI/ext4 layout for the virtio block device.
#
# This VM mirrors production closely so app integration tests run in realistic
# conditions before promotion. Stacks are ephemeral — reset the VM to clean state
# between test cycles.
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

  # Uncomment after creating secrets/hosts/sandbox.yaml with root.passwordHash:
  # infra.security.sops = {
  #   enable          = true;
  #   defaultSopsFile = ../../../secrets/hosts/sandbox.yaml;
  # };
  # infra.users.root = {
  #   enable   = true;
  #   sopsFile = ../../../secrets/hosts/sandbox.yaml;
  # };
}

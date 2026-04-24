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
#
# OrbStack bootstrap requirement
# ------------------------------
# When promoting an existing OrbStack VM into this `homelab` host, the first
# `nixos-rebuild switch` will fail unless:
#   1. `/var/lib/sops-nix/key.txt` exists and is the mfo Age private key — the
#      `admin` and `root` accounts use SOPS-managed password hashes
#      (`neededForUsers = true`), so activation cannot create the users without
#      the key.
#   2. SSH host keys are generated (`ssh-keygen -A`).
#   3. A compatibility user matching the current SSH login on the OrbStack VM
#      stays declared during the switch (NixOS removes undeclared accounts and
#      would kill the live SSH session mid-switch). The `mickael` user below
#      is kept for that reason; it ships mfo's pubkey so the operator can SSH
#      back in even if `admin` is not ready yet.
#
# Run `nix run .#bootstrap-host-on-orbstack` from the Mac host to satisfy
# (1) and (2) before the first promotion switch.
{ config, hostVars, lib, ... }:
let
  authorizedKeys = import ../../../modules/users/authorized-keys.nix;
in
{
  imports = [
    ../../../modules/profiles/server.nix
    ../../../modules/users/root.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone       = lib.mkDefault hostVars.timezone;
  i18n.defaultLocale  = lib.mkDefault hostVars.locale;
  system.stateVersion = "24.11";

  # On OrbStack, the VM kernel is provided by the hypervisor and there is no
  # mounted ESP — disable bootloader management to keep the switch persistent.
  # On real bare-metal homelab hardware, /opt/orbstack-guest is absent so
  # systemd-boot is enabled normally. Requires `--impure` so that pathExists
  # can read outside the Nix store; reconfigure.sh passes it.
  boot.loader.systemd-boot.enable      = lib.mkDefault (! builtins.pathExists "/opt/orbstack-guest");
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault (! builtins.pathExists "/opt/orbstack-guest");
  boot.loader.grub.enable              = lib.mkDefault (! builtins.pathExists "/opt/orbstack-guest");

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../secrets/hosts/homelab.yaml;
  };

  infra.users.admin.hashedPasswordFile =
    config.sops.secrets."homelab/users/admin-password-hash".path;
  infra.users.admin.sshAuthorizedKeys = authorizedKeys.mfo;

  infra.users.root = {
    enable = true;
    sopsFile = ../../../secrets/common.yaml;
  };

  # OrbStack bootstrap compatibility user. Kept declared so an in-place
  # `nixos-rebuild switch` from the OrbStack default image does not remove
  # the live SSH login. Safe to keep once `admin` is verified.
  users.users.mickael = {
    isNormalUser = true;
    description = "OrbStack migration compatibility user";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = authorizedKeys.mfo;
  };

  services.cockpit = {
    enable = true;
    openFirewall = true;
  };

  sops.secrets."homelab/users/admin-password-hash" = {
    key = "hosts/homelab/users/admin/passwordHash";
    neededForUsers = true;
  };
}

# Server-class profile (vendored from the previous `homelab`
# `nix/profiles/server.nix`, adapted to the local `infra.*` namespace).
#
# Imports the modules a headless server needs together:
# - hardened sudo;
# - hardened SSH (key-only, no root password login by default);
# - server firewall (SSH open, tailscale0 trusted);
# - generic admin user (opt-in keys/password);
# - Tailscale.
#
# This profile does not pin a hostname, locale or stack assignment — those
# remain target-local responsibilities in `targets/hosts/<name>/`.
{ ... }:
{
  imports = [
    ../security/server.nix
    ../security/ssh.nix
    ../networking/firewall-server.nix
    ../networking/tailscale.nix
    ../users/admin.nix
  ];

  infra.security.server.enable = true;
  infra.security.ssh = {
    enable = true;
    permitRootLogin = "prohibit-password";
  };
  infra.networking.firewallServer.enable = true;
  infra.networking.tailscale.enable = true;
  infra.users.admin.enable = true;
}

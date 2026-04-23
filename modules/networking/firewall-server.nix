# Server-side firewall baseline (vendored from the previous `homelab`
# `nix/modules/networking/`).
#
# - Enables the firewall;
# - opens SSH (22/tcp) so the host stays reachable;
# - trusts the `tailscale0` interface so intra-mesh traffic flows without
#   per-service rules. This complements `infra.networking.tailscale` (which
#   only enables the daemon and routing features).
#
# Workstations do not import this profile by default: they currently rely on
# the NixOS default firewall behaviour and do not need the explicit `tailscale0`
# trust. Server-class hosts opt in via `infra.networking.firewallServer.enable`.
{ lib, config, ... }:
let
  cfg = config.infra.networking.firewallServer;
in
{
  options.infra.networking.firewallServer = {
    enable = lib.mkEnableOption "Server firewall baseline (SSH + tailscale0 trust)";

    extraTrustedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional interfaces to trust beyond `tailscale0`.";
    };

    extraAllowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "Additional TCP ports to allow beyond SSH.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = lib.mkDefault ([ 22 ] ++ cfg.extraAllowedTCPPorts);
      trustedInterfaces = [ "tailscale0" ] ++ cfg.extraTrustedInterfaces;
    };
  };
}

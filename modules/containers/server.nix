# Server-side container baseline.
#
# Activates Docker via `infra.containers.docker`, gives the standard server
# operator accounts membership in the docker group, and opens HTTP/HTTPS so
# that workloads operated through `dokploy` or directly via `docker compose`
# can serve traffic without per-stack firewall edits.
{ lib, config, ... }:
let
  cfg = config.infra.containers.server;
in
{
  options.infra.containers.server = {
    enable = lib.mkEnableOption "Server container baseline (Docker + 80/443 + admin/root in docker group)";

    httpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ 80 443 ];
      description = "TCP ports opened on the host firewall for HTTP/HTTPS workloads.";
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Operator account added to the docker group alongside root.";
    };
  };

  config = lib.mkIf cfg.enable {
    infra.containers.docker.enable = true;

    users.groups.docker.members = [ cfg.adminUser "root" ];

    networking.firewall.allowedTCPPorts = cfg.httpPorts;
  };
}

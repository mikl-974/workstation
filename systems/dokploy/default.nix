# Dokploy host preparation module.
#
# Dokploy itself is *not* installed by Nix — it is operated externally and
# orchestrates Docker workloads. This module only prepares the host the way
# Dokploy expects: a working Docker engine, the standard admin/docker group
# membership, and HTTP/HTTPS open on the firewall.
{ lib, config, ... }:
let
  cfg = config.infra.dokploy;
in
{
  imports = [
    ../containers/docker.nix
    ../containers/server.nix
  ];

  options.infra.dokploy = {
    enable = lib.mkEnableOption "Dokploy host preparation (Docker + 80/443 + groups)";

    adminUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Operator account added to the docker group alongside root.";
    };
  };

  config = lib.mkIf cfg.enable {
    infra.containers.server = {
      enable = true;
      adminUser = cfg.adminUser;
    };
  };
}

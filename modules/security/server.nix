# Hardened sudo baseline for server-class hosts (vendored from the previous
# `homelab` repo `nix/modules/security/`).
#
# Activated via `infra.security.server.enable` rather than imposed by import,
# so that workstations with a different sudo policy are not silently affected.
{ lib, config, ... }:
let
  cfg = config.infra.security.server;
in
{
  options.infra.security.server.enable =
    lib.mkEnableOption "Hardened sudo baseline for server-class hosts";

  config = lib.mkIf cfg.enable {
    security.sudo = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = true;
    };
  };
}

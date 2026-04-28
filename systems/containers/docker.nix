# Server-side Docker engine (vendored from the previous `foundation` flake).
#
# This is distinct from `systems/containers/podman.nix`, which is the
# *workstation* developer container backend. Hosts that operate workloads
# through Docker (e.g. Dokploy on `contabo`) opt in via
# `infra.containers.docker.enable = true`.
{ lib, config, ... }:
let
  cfg = config.infra.containers.docker;
in
{
  options.infra.containers.docker = {
    enable = lib.mkEnableOption "Docker engine for server-class hosts";

    rootless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Docker rootless mode.";
    };

    daemonSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional Docker daemon settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      rootless.enable = lib.mkDefault cfg.rootless;
      daemon.settings = cfg.daemonSettings;
    };
  };
}

{ lib, config, hostVars, ... }:
let
  cfg = config.workstation.containers.podman;
  podmanUsers = hostVars.users or [ hostVars.username ];
in
{
  options.workstation.containers.podman.enable =
    lib.mkEnableOption "local Podman container engine for workstation development";

  config = lib.mkIf cfg.enable {
    # Podman is enabled here as a local developer container backend.
    # It is not modeled as a shared infra primitive in this repo: the chosen
    # UX is workstation-specific (dev profile + Docker-compatible CLI/socket).
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    users.users = lib.genAttrs podmanUsers (_: {
      extraGroups = lib.mkAfter [ "podman" ];
    });
  };
}

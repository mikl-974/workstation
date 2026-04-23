# Tailscale shared module (vendored from the previous `foundation` flake).
#
# Why this lives here now:
# - `infra` is the single source of truth for this monorepo.
# - The `foundation` repo was a thin shared layer with only one option set
#   actively consumed here (`networking.tailscale`). Keeping it as an external
#   flake input added supply-chain surface and an extra repo to maintain for
#   no real composition benefit, since no other repo consumed it.
# - Vendoring keeps the contract identical (option shape unchanged) but moves
#   the namespace under `infra.networking.*`, in line with the rest of the
#   repo (`infra.security.sops`, `infra.stacks.openclaw`, ...).
{ lib, config, ... }:
let
  cfg = config.infra.networking.tailscale;
in
{
  options.infra.networking.tailscale = {
    enable = lib.mkEnableOption "Tailscale shared infra module";

    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum [ "none" "client" "server" "both" ];
      default = "client";
      description = "Routing mode passed to services.tailscale.useRoutingFeatures.";
    };

    extraSetFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra flags passed to tailscale set via services.tailscale.extraSetFlags.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = lib.mkDefault cfg.useRoutingFeatures;
      extraSetFlags = cfg.extraSetFlags;
    };
  };
}

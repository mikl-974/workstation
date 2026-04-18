{ ... }:
{
  # Tailscale is consumed from the foundation shared module.
  # The NixOS module (foundation.nixosModules.networkingTailscale) is
  # registered at the flake level so the option namespace is always available.
  foundation.networking.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
}

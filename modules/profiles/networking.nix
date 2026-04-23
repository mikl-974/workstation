{ ... }:
{
  # Tailscale is consumed from the foundation shared module.
  # The NixOS module (foundation.nixosModules.networkingTailscale) is
  # registered at the flake level so the option namespace is always available.
  foundation.networking.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # DNS fallback — the DHCP-provided DNS (172.16.185.2) may not resolve
  # public hostnames. 1.1.1.1 and 8.8.8.8 are used as reliable fallbacks.
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
}

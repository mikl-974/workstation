{ ... }:
{
  # Tailscale is consumed from the local infra module.
  # The NixOS module (./modules/networking/tailscale.nix) is registered at the
  # flake level via sharedModules so the option namespace is always available.
  infra.networking.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # DNS fallback — the DHCP-provided DNS (172.16.185.2) may not resolve
  # public hostnames. 1.1.1.1 and 8.8.8.8 are used as reliable fallbacks.
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
}

{ ... }:
{
  # Temporary compatibility fallback for legacy targets not yet migrated to home/targets/
  # (currently gaming only). Remove it once that host gets an explicit home/targets/.
  #
  # Normalized user identities available in this repo:
  #   - ./mfo.nix  = Mickaël Folio
  #   - ./dfo.nix  = Delphine Folio
  #   - ./zfo.nix  = Zoé Folio
  #   - ./lfo.nix  = Léna Folio
  #
  # This file does NOT activate all users. Real assignment stays explicit in
  # home/targets/<host>.nix. This module only preserves the legacy single-user
  # fallback path for older hosts.
  imports = [
    ./base.nix
    ../roles/desktop-hyprland.nix
  ];
}

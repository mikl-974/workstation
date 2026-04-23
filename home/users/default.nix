{ ... }:
{
  # Temporary compatibility fallback for legacy targets not yet migrated to home/targets/
  # (currently laptop and gaming). Remove it once those hosts get explicit home/targets/.
  imports = [
    ./base.nix
    ../roles/desktop-hyprland.nix
  ];
}

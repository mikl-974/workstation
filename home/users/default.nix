{ ... }:
{
  # Temporary compatibility fallback for legacy targets not yet migrated to home/targets/.
  imports = [
    ./base.nix
    ../roles/desktop-hyprland.nix
  ];
}

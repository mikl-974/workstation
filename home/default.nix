{ ... }:
{
  imports = [
    ./noctalia.nix
  ];

  home.stateVersion = "24.11";
  xdg.enable = true;

  # ── Dotfiles ────────────────────────────────────────────────────────────────
  # Raw config files managed via symlinks.
  # See dotfiles/README.md for the full convention.
  home.file = {
    ".config/hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
    ".config/foot/foot.ini".source      = ../dotfiles/foot/foot.ini;
  };
}

{ ... }:
{
  home.stateVersion = "24.11";
  xdg.enable = true;

  # Dotfiles — raw applicative config files managed via symlinks.
  # Add entries here as dotfiles are placed in dotfiles/<app>/.
  # See dotfiles/README.md for the full convention.
  #
  # Example (uncomment when the file exists):
  # home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
  # home.file.".config/foot/foot.ini".source       = ../dotfiles/foot/foot.ini;
  # home.file.".config/wofi/config".source         = ../dotfiles/wofi/config;
  # home.file.".config/wofi/style.css".source      = ../dotfiles/wofi/style.css;
  home.file = {};
}

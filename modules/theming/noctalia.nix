{ lib, config, pkgs, ... }:
let
  cfg = config.workstation.theming.noctalia;
in
{
  # Noctalia is the personal color scheme and visual identity of this workstation.
  # It is intentionally kept in workstation — it is not a generic theme primitive.
  #
  # At this stage, this module:
  #   - installs the base theming packages (GTK, icons, cursor)
  #   - sets system-level GTK theme environment variables
  #   - provides the activation point for all future Noctalia theming work
  #
  # Dotfiles (Hyprland colors, waybar CSS, foot theme, etc.) live in dotfiles/noctalia/
  # and are managed through Home Manager (home/default.nix).
  options.workstation.theming.noctalia.enable =
    lib.mkEnableOption "Noctalia personal theme and color scheme";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # GTK base
      adwaita-icon-theme
      gnome-themes-extra
      # Cursor theme — can be swapped for a Noctalia-specific cursor later
      bibata-cursors
    ];

    # GTK theme environment — will be overridden per-user via home-manager
    environment.sessionVariables = {
      GTK_THEME = "Adwaita:dark";
    };
  };
}

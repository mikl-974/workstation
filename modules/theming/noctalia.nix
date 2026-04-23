# System-level Noctalia integration.
# See https://docs.noctalia.dev/getting-started/nixos/
#
# This module:
#   - installs the noctalia-shell package from the flake input
#   - installs GTK/icon/cursor theming packages
#   - enables NixOS services required by Noctalia (bluetooth, upower, etc.)
#
# Per-user shell configuration (colors, bar settings) lives in home/noctalia.nix
# via the Home Manager module.
{ lib, config, pkgs, inputs, ... }:
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
  # Dotfiles (Hyprland colors, waybar CSS, foot theme, etc.) live in dotfiles/themes/noctalia/
  # and are managed through the active Home Manager composition.
  options.workstation.theming.noctalia.enable =
    lib.mkEnableOption "Noctalia desktop shell and personal theme";

  config = lib.mkIf cfg.enable {
    # Install the noctalia-shell package from the flake input.
    environment.systemPackages = with pkgs; [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      # GTK base
      adwaita-icon-theme
      gnome-themes-extra
      # Cursor theme
      bibata-cursors
    ];

    # GTK theme environment
    environment.sessionVariables = {
      GTK_THEME = "Adwaita:dark";
    };
  };
}

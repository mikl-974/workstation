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

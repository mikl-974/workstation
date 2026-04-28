# System-level Noctalia integration.
# See https://docs.noctalia.dev/getting-started/nixos/
#
# Upstream treats Noctalia as a desktop shell configured via its Home Manager
# module. This module keeps only workstation-wide visual dependencies and
# session defaults. The shell package and its JSON config live in
# home/roles/noctalia.nix.
{ lib, config, pkgs, ... }:
let
  cfg = config.workstation.theming.noctalia;
in
{
  options.workstation.theming.noctalia.enable =
    lib.mkEnableOption "Noctalia desktop shell integration";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      adwaita-icon-theme
      gnome-themes-extra
      bibata-cursors
    ];

    environment.sessionVariables = {
      GTK_THEME = "Adwaita:dark";
    };
  };
}

{ lib, ... }:
{
  imports = [ ./base.nix ];

  home.username = "mfo";
  home.homeDirectory = "/home/mfo";

  # desktop-hyprland.nix provides the default profile.conf; mfo overrides only
  # the app-selection layer so Hyprland keeps the shared base but uses Chromium.
  home.file.".config/hypr/profile.conf".source = lib.mkForce ../../dotfiles/hyprland/profiles/mfo.conf;

  home.sessionVariables.BROWSER = "chromium";
}

{ lib, ... }:
{
  imports = [ ./base.nix ];

  home.username = "mfo";
  home.homeDirectory = "/home/mfo";

  home.file.".config/hypr/profile.conf".source = lib.mkForce ../../dotfiles/hyprland/profiles/mfo.conf;

  home.sessionVariables.BROWSER = "chromium";
}

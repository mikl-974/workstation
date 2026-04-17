{ pkgs, ... }:
{
  imports = [
    ./noctalia.nix
  ];

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra
  ];
}

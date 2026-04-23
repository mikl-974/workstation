{ pkgs, ... }:
{
  imports = [
    ./daily.nix
    ./utilities.nix
  ];

  environment.systemPackages = with pkgs; [
    xdg-utils
    file
    ripgrep
    chromium
  ];
}

{ pkgs, ... }:
let
  jetbrainsMono = pkgs.nerd-fonts.jetbrains-mono;
in
{
  environment.systemPackages = [
    pkgs.vim
    pkgs.neovim
    pkgs.alacritty
    pkgs.vscode
  ];

  fonts.packages = [ jetbrainsMono ];
}

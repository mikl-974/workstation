{ pkgs, ... }:
let
  jetbrainsMono = pkgs.nerd-fonts.jetbrains-mono;
in
{
  # Nix remains the preferred path when the package is available cleanly on macOS.
  environment.systemPackages = [
    pkgs.vim
    pkgs.neovim
    pkgs.alacritty
    pkgs.vscode
  ];

  fonts.packages = [ jetbrainsMono ];

  # Homebrew casks stay explicit here because they are GUI macOS applications.
  homebrew.casks = [
    "moonlight"
    "omniwm"
  ];
}

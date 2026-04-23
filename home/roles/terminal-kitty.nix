{ pkgs, ... }:
{
  home.packages = [ pkgs.kitty ];

  home.file = {
    ".config/kitty/kitty.conf".source = ../../dotfiles/terminal/kitty.conf;
    ".config/kitty/profile.conf".source = ../../dotfiles/terminal/profiles/default-kitty.conf;
  };
}

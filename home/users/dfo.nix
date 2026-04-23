{ lib, ... }:
{
  imports = [ ./base.nix ];

  home.username = "dfo";
  home.homeDirectory = "/home/dfo";

  home.file.".config/kitty/profile.conf".source = lib.mkForce ../../dotfiles/terminal/profiles/dfo-kitty.conf;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      clock-format = "24h";
      show-battery-percentage = true;
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Nautilus.desktop"
        "org.gnome.Console.desktop"
      ];
    };
  };

  home.sessionVariables.BROWSER = "firefox";
}

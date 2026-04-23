{ ... }:
{
  xdg.configFile."gtk-3.0/settings.ini".source = ../../dotfiles/themes/noctalia/gtk/settings.ini;
  xdg.configFile."gtk-4.0/settings.ini".source = ../../dotfiles/themes/noctalia/gtk/settings.ini;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "GNOME";
    XDG_SESSION_TYPE = "wayland";
  };
}

{ ... }:
{
  home.file = {
    ".config/hypr/hyprland.conf".source = ../../dotfiles/hyprland/hyprland.conf;
    # profile.conf is the explicit user override point for terminal/launcher/browser.
    ".config/hypr/profile.conf".source = ../../dotfiles/hyprland/profiles/default.conf;
    ".config/foot/foot.ini".source = ../../dotfiles/terminal/foot.ini;
    ".config/wofi/config".source = ../../dotfiles/launchers/config;
    ".config/wofi/style.css".source = ../../dotfiles/launchers/style.css;
    ".config/mako/config".source = ../../dotfiles/notifications/config;
  };

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
  };
}

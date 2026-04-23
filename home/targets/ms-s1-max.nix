#
# Home Manager composition for the concrete target `ms-s1-max`.
# This file binds normalized user identities from `home/users/` to reusable
# roles from `home/roles/`, plus the target-specific overrides that are really
# needed on this machine.
{
  mfo = { lib, ... }: {
    imports = [
      ../users/mfo.nix
      ../roles/desktop-hyprland.nix
      ../roles/gaming-steam.nix
      ../roles/browser-chromium.nix
    ];

    # `ms-s1-max` keeps a Chromium-specific Hyprland profile for mfo.
    home.file.".config/hypr/profile.conf".source = lib.mkForce ../../dotfiles/hyprland/profiles/mfo.conf;
    home.sessionVariables.BROWSER = "chromium";
  };

  dfo = { lib, ... }: {
    imports = [
      ../users/dfo.nix
      ../roles/desktop-gnome.nix
      ../roles/gaming-lutris.nix
      ../roles/gaming-steam.nix
      ../roles/browser-firefox.nix
      ../roles/terminal-kitty.nix
    ];

    # `ms-s1-max` keeps user-specific GNOME and Kitty preferences for dfo.
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
  };
}

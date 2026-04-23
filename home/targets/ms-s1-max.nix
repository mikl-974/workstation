#
# Home Manager composition for the concrete target `ms-s1-max`.
# This file binds real users from `home/users/` to reusable roles from
# `home/roles/` without moving machine logic into Home Manager itself.
{
  mfo = {
    imports = [
      ../users/mfo.nix
      ../roles/desktop-hyprland.nix
      ../roles/gaming-steam.nix
      ../roles/browser-chromium.nix
    ];
  };

  dfo = {
    imports = [
      ../users/dfo.nix
      ../roles/desktop-gnome.nix
      ../roles/gaming-lutris.nix
      ../roles/gaming-steam.nix
      ../roles/browser-firefox.nix
      ../roles/terminal-kitty.nix
    ];
  };
}

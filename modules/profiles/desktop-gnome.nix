{ ... }:
{
  imports = [
    ../desktop/gnome.nix
    ../apps/default.nix
    ../shell/default.nix
    ../theming/default.nix
  ];

  workstation.theming.noctalia.enable = true;
}

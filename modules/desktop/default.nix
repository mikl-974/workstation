{ pkgs, ... }:
{
  imports = [
    ./hyprland.nix
    ./audio.nix
    ./connectivity.nix
    ./portals.nix
    ./fonts.nix
    ./warp.nix
  ];

  hardware.graphics.enable = true;
  security.polkit.enable = true;
  services.dbus.enable = true;
  services.greetd.enable = true;
  services.greetd.settings.default_session = {
    # Generic greetd default for Hyprland-centric hosts; mixed-desktop hosts can
    # still override or disable greetd at the target level.
    command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
    user = "greeter";
  };
}

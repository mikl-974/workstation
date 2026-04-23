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
    # Keep session choice explicit on mixed-desktop targets such as ms-s1-max.
    command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
    user = "greeter";
  };
}

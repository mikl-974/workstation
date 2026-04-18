{ pkgs, ... }:
{
  imports = [
    ./hyprland.nix
    ./audio.nix
    ./portals.nix
    ./fonts.nix
    ./warp.nix
  ];

  hardware.graphics.enable = true;
  networking.networkmanager.enable = true;
  security.polkit.enable = true;
  services.dbus.enable = true;
  services.greetd.enable = true;
  services.greetd.settings.default_session = {
    command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
    user = "greeter";
  };
}

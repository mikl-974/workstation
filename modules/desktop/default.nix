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
  # Charger les modules DRM au démarrage (Intel, AMD, virtio-gpu)
  # — ignorés silencieusement si le matériel est absent
  boot.initrd.kernelModules = [ "drm" ];
  boot.kernelModules        = [ "i915" "amdgpu" "virtio-gpu" ];
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  security.polkit.enable = true;
  services.dbus.enable = true;
  services.greetd.enable = true;
  services.greetd.settings.default_session = {
    command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
    user = "greeter";
  };
}

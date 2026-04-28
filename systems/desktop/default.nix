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
  # Load DRM modules at boot (Intel, AMD, virtio-gpu)
  # — silently ignored if the hardware is absent
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
    # Generic greetd default for Hyprland-centric hosts; mixed-desktop hosts can
    # still override or disable greetd at the target level.
    # No --remember here: keep the greeter stateless unless a target opts in.
    command = ''
      ${pkgs.tuigreet}/bin/tuigreet --time --cmd "${pkgs.uwsm}/bin/uwsm start hyprland.desktop"
    '';
    user = "greeter";
  };
}

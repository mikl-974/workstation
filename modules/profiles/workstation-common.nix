# Common NixOS workstation baseline.
# Import this profile, then layer host-local responsibilities on top
# inside `targets/hosts/<name>/config/`.
{ hostVars, ... }:
{
  imports = [
    ./desktop-hyprland.nix
    ./networking.nix
    ../security/ssh.nix
  ];

  # Workstations expose SSH (key-only) so mfo can connect from anywhere on the tailnet.
  infra.security.ssh.enable = true;

  nixpkgs.config.allowUnfree = true;

  networking.hostName = hostVars.hostname;
  time.timeZone      = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  # QWERTY keyboard — console (TTY) and X11/Wayland.
  console.keyMap              = "us";
  services.xserver.xkb.layout = "us";

  # EFI systemd-boot — matches the disko ESP layout at /boot.
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
}

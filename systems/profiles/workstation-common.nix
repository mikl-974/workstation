# Common NixOS workstation baseline.
# Import this profile, then layer host-local responsibilities on top
# inside `targets/hosts/<name>/config/`.
{ hostVars, ... }:
{
  imports = [
    ./desktop-hyprland.nix
    ./desktop-mangowm.nix
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

  # QWERTY keyboard with AltGr dead keys, mirrored to the TTY for local recovery.
  console.useXkbConfig = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
    options = "lv3:ralt_switch"; # Force le Alt droit à devenir AltGr
  };

  # EFI systemd-boot — matches the disko ESP layout at /boot.
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZRAM compressed swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # OOM killer pour processes système
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };
}

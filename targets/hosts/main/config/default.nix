{ hostVars, ... }:
{
  imports = [
    ../../../../modules/profiles/desktop-hyprland.nix
    ../../../../modules/profiles/dev.nix
    ../../../../modules/profiles/networking.nix
    ./user.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  # Boot: EFI systemd-boot — matches the disko ESP at /boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}

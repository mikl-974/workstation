{ hostVars, ... }:
{
  imports = [
    ./disko.nix
    ../../profiles/desktop-hyprland.nix
    ../../profiles/dev.nix
    ../../profiles/networking.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  # Boot: EFI systemd-boot — matches the disko ESP at /boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${hostVars.username} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "docker" "networkmanager" "video" "audio" ];
  };
}

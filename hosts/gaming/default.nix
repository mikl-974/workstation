{ hostVars, ... }:
{
  imports = [
    ../../profiles/desktop-hyprland.nix
    ../../profiles/gaming.nix
    ../../profiles/networking.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${hostVars.username} = {
    isNormalUser    = true;
    extraGroups     = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = hostVars.initialPassword;
  };

  users.users.root = {
    initialPassword = hostVars.initialPassword;
  };
}

{ hostVars, ... }:
{
  imports = [
    ../../profiles/desktop-hyprland.nix
    ../../profiles/dev.nix
    ../../profiles/networking.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  users.users.${hostVars.username} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "docker" "networkmanager" "video" "audio" ];
  };
}

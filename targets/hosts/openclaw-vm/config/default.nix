{ hostVars, ... }:
{
  imports = [
    ../../../../modules/profiles/networking.nix
    ../../../../modules/profiles/virtual-machine.nix
    ../../../../stacks/openclaw/default.nix
    ./user.nix
  ];

  networking.hostName = hostVars.hostname;
  time.timeZone = hostVars.timezone;
  i18n.defaultLocale = hostVars.locale;
  system.stateVersion = "24.11";

  boot.loader.systemd-boot.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  infra.stacks.openclaw = {
    enable = true;
    bind = "tailnet";
    config = {
      gateway = {
        mode = "local";
        auth.mode = "token";
      };
      discovery.mdns.mode = "minimal";
    };
  };
}

{ config, hostVars, ... }:
{
  imports = [
    ../../../../modules/profiles/networking.nix
    ../../../../modules/profiles/virtual-machine.nix
    ../../../../modules/users/root.nix
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

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../../secrets/hosts/openclaw-vm.yaml;
  };

  infra.users.root = {
    enable = true;
    sopsFile = ../../../../secrets/common.yaml;
  };

  sops.secrets."openclaw-vm/users/openclaw-password-hash" = {
    key = "hosts/openclaw-vm/users/openclaw/passwordHash";
    neededForUsers = true;
  };

  users.users.openclaw.hashedPasswordFile =
    config.sops.secrets."openclaw-vm/users/openclaw-password-hash".path;

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

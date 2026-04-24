{ config, ... }:
{
  imports = [
    ../../../../modules/profiles/workstation-common.nix
    ../../../../modules/users/root.nix
    ../../../../modules/profiles/dev.nix
    ./user.nix
  ];

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../../secrets/hosts/main.yaml;
  };

  infra.users.root = {
    enable = true;
    sopsFile = ../../../../secrets/common.yaml;
  };

  sops.secrets."main/users/mfo-password-hash" = {
    key = "hosts/main/users/mfo/passwordHash";
    neededForUsers = true;
  };

  users.users.mfo.hashedPasswordFile =
    config.sops.secrets."main/users/mfo-password-hash".path;
}

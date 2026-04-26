{ config, ... }:
{
  imports = [
    ../../../../modules/profiles/workstation-common.nix
    ../../../../modules/users/root.nix
    ./user.nix
    ./capabilities.nix
  ];

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../../secrets/hosts/ms-s1-max.yaml;
  };

  infra.users.root = {
    enable = true;
    sopsFile = ../../../../secrets/common.yaml;
  };

  sops.secrets."ms-s1-max/users/mfo-password-hash" = {
    key = "hosts/ms-s1-max/users/mfo/passwordHash";
    neededForUsers = true;
  };

  users.users.mfo.hashedPasswordFile =
    config.sops.secrets."ms-s1-max/users/mfo-password-hash".path;
}

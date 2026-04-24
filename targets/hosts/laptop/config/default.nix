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
    defaultSopsFile = ../../../../secrets/hosts/laptop.yaml;
  };

  infra.users.root = {
    enable = true;
    sopsFile = ../../../../secrets/common.yaml;
  };

  sops.secrets."laptop/users/mfo-password-hash" = {
    key = "hosts/laptop/users/mfo/passwordHash";
    neededForUsers = true;
  };

  users.users.mfo.hashedPasswordFile =
    config.sops.secrets."laptop/users/mfo-password-hash".path;
}

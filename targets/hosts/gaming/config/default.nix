{ config, ... }:
{
  imports = [
    ../../../../modules/profiles/workstation-common.nix
    ../../../../modules/users/root.nix
    ../../../../modules/profiles/gaming.nix
    ./user.nix
  ];

  infra.security.sops = {
    enable = true;
    defaultSopsFile = ../../../../secrets/hosts/gaming.yaml;
  };

  infra.users.root = {
    enable = true;
    sopsFile = ../../../../secrets/common.yaml;
  };

  sops.secrets."gaming/users/mfo-password-hash" = {
    key = "hosts.gaming.users.mfo.passwordHash";
    neededForUsers = true;
  };

  users.users.mfo.hashedPasswordFile =
    config.sops.secrets."gaming/users/mfo-password-hash".path;
}

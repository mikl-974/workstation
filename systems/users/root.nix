# Root user — shared password managed via sops.
#
# The password hash is stored in a sops-encrypted YAML file under the key
# `root.passwordHash`. Generate and add it with:
#
#   mkpasswd --method=yescrypt        # → paste the hash into your editor
#   sops secrets/hosts/<host>.yaml    # or secrets/common.yaml
#
# Then add:
#   root:
#     passwordHash: '<hash>'
#
# Enable in a host config:
#
#   imports = [ ../../../systems/users/root.nix ];
#   infra.users.root = {
#     enable   = true;
#     sopsFile = ../../../secrets/hosts/<host>.yaml;  # or secrets/common.yaml
#   };
#
# For servers, root SSH login remains governed by the SSH module
# (permitRootLogin = "prohibit-password" by default — key-only).
{ lib, config, ... }:
let
  cfg = config.infra.users.root;
in
{
  options.infra.users.root = {
    enable = lib.mkEnableOption "root user with sops-managed password";

    sopsFile = lib.mkOption {
      type        = lib.types.path;
      description = ''
        Path to the sops-encrypted YAML file that contains the
        `root.passwordHash` key (output of mkpasswd --method=yescrypt).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."root/passwordHash" = {
      sopsFile       = cfg.sopsFile;
      neededForUsers = true;
    };

    users.users.root.hashedPasswordFile =
      config.sops.secrets."root/passwordHash".path;
  };
}

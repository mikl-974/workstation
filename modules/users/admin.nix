# Generic admin user (vendored from the previous `foundation` flake).
#
# Provides `infra.users.admin.*`. Server-class hosts in this repo use this
# user as the operator account that receives SSH keys for NixOS Anywhere
# bootstrap and Colmena deployment.
{ lib, config, ... }:
let
  cfg = config.infra.users.admin;
in
{
  options.infra.users.admin = {
    enable = lib.mkEnableOption "generic admin user";

    name = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Name of the admin user to create.";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "wheel" ];
      description = "Additional groups assigned to the admin user.";
    };

    sshAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH authorized keys for the admin user.";
    };

    hashedPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional hashed password for the admin user.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} =
      {
        isNormalUser = true;
        description = "infra administrator";
        extraGroups = cfg.extraGroups;
        openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
      }
      // lib.optionalAttrs (cfg.hashedPassword != null) {
        inherit (cfg) hashedPassword;
      };
  };
}

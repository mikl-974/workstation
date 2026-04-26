# OpenSSH hardening module (vendored from the previous `foundation` flake).
#
# Provides `infra.security.ssh.*` for hosts that want a hardened SSH baseline.
# This module is opt-in so each host keeps control of its SSH posture.
{ lib, config, ... }:
let
  cfg = config.infra.security.ssh;
in
{
  options.infra.security.ssh = {
    enable = lib.mkEnableOption "OpenSSH hardened baseline";

    passwordAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow password-based SSH authentication.";
    };

    permitRootLogin = lib.mkOption {
      type = lib.types.enum [ "yes" "prohibit-password" "forced-commands-only" "no" ];
      default = "no";
      description = "Value for services.openssh.settings.PermitRootLogin.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = cfg.passwordAuthentication;
        PermitRootLogin = cfg.permitRootLogin;
      };
    };
  };
}

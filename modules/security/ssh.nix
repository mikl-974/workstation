# OpenSSH hardening module (vendored from the previous `foundation` flake).
#
# Provides `infra.security.ssh.*` for hosts that want a hardened SSH baseline.
# Workstations that already configure `services.openssh` directly (e.g.
# `targets/hosts/openclaw-vm`) can keep doing so; this module is opt-in.
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

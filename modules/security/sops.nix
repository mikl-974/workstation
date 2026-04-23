{ lib, config, ... }:
let
  cfg = config.infra.security.sops;
in
{
  options.infra.security.sops = {
    enable = lib.mkEnableOption "sops-nix integration for this target";

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sops-nix/key.txt";
      description = "Path to the Age private key used by sops-nix on the target.";
    };

    defaultSopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional default SOPS file for this target.";
    };

    defaultSopsFormat = lib.mkOption {
      type = lib.types.enum [ "yaml" "json" "dotenv" "binary" ];
      default = "yaml";
      description = "Default format used when a default SOPS file is configured.";
    };
  };

  config = lib.mkIf cfg.enable ({
    sops.age.keyFile = cfg.ageKeyFile;
  } // lib.optionalAttrs (cfg.defaultSopsFile != null) {
    sops.defaultSopsFile = cfg.defaultSopsFile;
    sops.defaultSopsFormat = cfg.defaultSopsFormat;
  });
}

{ lib, config, inputs, pkgs, ... }:
let
  cfg = config.infra.security.sops;
  sopsInstallSecretsRuntimeOnly =
    inputs.sops-nix.packages.${pkgs.system}.sops-install-secrets.overrideAttrs
      (_: {
        outputs = [ "out" ];
        postInstall = "";
      });
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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      sops.package = lib.mkDefault sopsInstallSecretsRuntimeOnly;
      sops.age.keyFile = cfg.ageKeyFile;
    })
    (lib.mkIf (cfg.enable && cfg.defaultSopsFile != null) {
      sops.defaultSopsFile = cfg.defaultSopsFile;
      sops.defaultSopsFormat = cfg.defaultSopsFormat;
    })
  ];
}

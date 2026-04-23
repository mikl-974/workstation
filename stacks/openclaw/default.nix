{ lib, config, pkgs, flakeInputs, ... }:
let
  cfg = config.infra.stacks.openclaw;
  upstreamPackages = flakeInputs.nix-openclaw.packages.${pkgs.system};
  secretEnvironmentSecretName = "openclaw/env";
  generatedSecretsDir = "${cfg.dataDir}/secrets";
  generatedGatewayTokenEnvFile = "${generatedSecretsDir}/gateway-token.env";
  secretEnvironmentFile =
    if cfg.secrets.sopsFile != null
    then config.sops.secrets.${secretEnvironmentSecretName}.path
    else null;
in
{
  imports = [
    flakeInputs.nix-openclaw.nixosModules.openclaw-gateway
  ];

  options.infra.stacks.openclaw = {
    enable = lib.mkEnableOption "OpenClaw application stack";

    package = lib.mkOption {
      type = lib.types.package;
      default = upstreamPackages.openclaw-gateway;
      description = "OpenClaw gateway package from the upstream nix-openclaw flake.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/openclaw";
      description = "Persistent OpenClaw application data directory.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/openclaw";
      description = "Host-local OpenClaw configuration directory.";
    };

    logDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/openclaw";
      description = "Host-local OpenClaw log directory.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "OpenClaw gateway listen port.";
    };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "tailnet";
      description = "Gateway bind target passed to the upstream OpenClaw config. `tailnet` keeps the first deployment off the public Internet.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the OpenClaw gateway port should be opened on the host firewall.";
    };

    publicEnvFile = lib.mkOption {
      type = lib.types.path;
      default = ./env/public.env;
      description = "Checked-in non-secret environment file materialized under /etc/openclaw/public.env.";
    };

    extraEnvironmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional EnvironmentFile entries passed to the upstream OpenClaw systemd unit.";
    };

    publicEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional non-secret environment variables injected directly into the upstream service.";
    };

    config = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Local typed overlay for the upstream OpenClaw JSON config.";
    };

    secrets = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Optional SOPS-managed dotenv file for OpenClaw runtime secrets.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "infra.stacks.openclaw currently targets Linux hosts through nix-openclaw.nixosModules.openclaw-gateway.";
      }
    ];

    infra.security.sops.enable = lib.mkDefault (cfg.secrets.sopsFile != null);

    sops.secrets.${secretEnvironmentSecretName} = lib.mkIf (cfg.secrets.sopsFile != null) {
      sopsFile = cfg.secrets.sopsFile;
      format = "dotenv";
      owner = "openclaw";
      group = "openclaw";
      mode = "0400";
    };

    systemd.tmpfiles.rules = [
      "d ${generatedSecretsDir} 0750 openclaw openclaw - -"
    ];

    environment.etc."openclaw/public.env".source = cfg.publicEnvFile;
    environment.etc."openclaw/stack-context".text = ''
      openclaw
      upstream=nix-openclaw
      upstreamModule=nixosModules.openclaw-gateway
      exposure=${cfg.bind}
      bootstrapSecret=${generatedGatewayTokenEnvFile}
    '';

    services.openclaw-gateway = {
      enable = true;
      package = cfg.package;
      port = cfg.port;
      stateDir = cfg.dataDir;
      configPath = "${cfg.configDir}/openclaw.json";
      logPath = "${cfg.logDir}/gateway.log";
      environment = cfg.publicEnvironment;
      environmentFiles =
        [ "/etc/openclaw/public.env" ]
        ++ [ generatedGatewayTokenEnvFile ]
        ++ lib.optionals (secretEnvironmentFile != null) [ secretEnvironmentFile ]
        ++ cfg.extraEnvironmentFiles;
      execStartPre = [
        ''
          ${pkgs.bash}/bin/bash -euo pipefail -c '
            install -d -m 0750 "${generatedSecretsDir}"
            if [[ ! -s "${generatedGatewayTokenEnvFile}" ]] || ! grep -q "^OPENCLAW_GATEWAY_TOKEN=" "${generatedGatewayTokenEnvFile}"; then
              token="$(head -c 32 /dev/urandom | base64 | tr -d "\n" | tr "/+" "_-")"
              printf "OPENCLAW_GATEWAY_TOKEN=%s\n" "$token" > "${generatedGatewayTokenEnvFile}"
              chmod 0400 "${generatedGatewayTokenEnvFile}"
            fi
          '
        ''
      ];
      servicePath = [ pkgs.gnugrep ];
      config = lib.recursiveUpdate {
        gateway = {
          mode = "local";
          bind = cfg.bind;
          auth.mode = "token";
        };
        discovery.mdns.mode = "minimal";
      } cfg.config;
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [ cfg.port ];
  };
}

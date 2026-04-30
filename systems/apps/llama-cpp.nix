{ lib, config, pkgs, ... }:
let
  cfg = config.infra.ai.inference.llamaCpp;

  inherit (lib)
    attrValues
    concatMapStringsSep
    escapeShellArg
    filterAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optional
    optionalAttrs
    types
    ;

  cacheRoot = "/var/lib/llama-cpp/cache";
  hfCacheDir = "${cacheRoot}/huggingface";
  llamaCacheDir = "${cacheRoot}/llama";
  modelsDir = "/var/lib/llama-cpp/models";

  resolve = default: value: if value == null then default else value;

  enabledModels = filterAttrs (_: modelCfg: modelCfg.enable) cfg.models;

  effectiveModel = name: modelCfg:
    let
      description =
        if modelCfg.description == null then
          "llama.cpp server for ${name}"
        else
          modelCfg.description;
    in
    {
      inherit description;
      package = resolve cfg.defaults.package modelCfg.package;
      host = resolve cfg.defaults.host modelCfg.host;
      port = modelCfg.port;
      source = modelCfg.source;
      model = modelCfg.model;
      modelPath = modelCfg.modelPath;
      ctxSize = resolve cfg.defaults.ctxSize modelCfg.ctxSize;
      fit = resolve cfg.defaults.fit modelCfg.fit;
      metrics = resolve cfg.defaults.metrics modelCfg.metrics;
      enableUnifiedMemory =
        resolve cfg.defaults.enableUnifiedMemory modelCfg.enableUnifiedMemory;
      openFirewall = resolve cfg.defaults.openFirewall modelCfg.openFirewall;
      autoStart = modelCfg.autoStart;
      extraArgs = modelCfg.extraArgs;
      extraEnvironment = cfg.defaults.extraEnvironment // modelCfg.extraEnvironment;
    };

  mkExecStart = effective:
    let
      baseArgs = [
        "${effective.package}/bin/llama-server"
      ] ++ (
        if effective.source == "hf" then
          [ "-hf" effective.model ]
        else
          [ "--model" effective.modelPath ]
      ) ++ [
        "--host"
        effective.host
        "--port"
        (toString effective.port)
        "--ctx-size"
        (toString effective.ctxSize)
        "-fit"
        effective.fit
      ] ++ optional effective.metrics "--metrics" ++ effective.extraArgs;
    in
    concatMapStringsSep " " escapeShellArg baseArgs;

  mkModelService = name: modelCfg:
    let
      effective = effectiveModel name modelCfg;
      environment =
        config.environment.variables
        // {
          HOME = "/var/lib/llama-cpp";
          HF_HOME = hfCacheDir;
          LLAMA_CACHE = llamaCacheDir;
          XDG_CACHE_HOME = cacheRoot;
        }
        // optionalAttrs effective.enableUnifiedMemory {
          GGML_CUDA_ENABLE_UNIFIED_MEMORY = "1";
        }
        // effective.extraEnvironment;
    in
    nameValuePair "llama-cpp-${name}" ({
      description = effective.description;
      after = [ "network.target" ] ++ optional (effective.source == "hf") "network-online.target";
      wants = optional (effective.source == "hf") "network-online.target";
      wantedBy = optional effective.autoStart "multi-user.target";
      environment = environment;
      unitConfig =
        optionalAttrs (effective.source == "local") {
          ConditionPathExists = effective.modelPath;
        }
        // {
          StartLimitIntervalSec = 0;
        };
      serviceConfig = {
        Type = "exec";
        User = "llama-cpp";
        Group = "llama-cpp";
        WorkingDirectory = "/var/lib/llama-cpp";
        ExecStart = mkExecStart effective;
        Restart = "on-failure";
        RestartSec = "15s";
        DeviceAllow = [
          "char-drm"
          "char-fb"
          "char-kfd"
        ];
        DevicePolicy = "closed";
        NoNewPrivileges = true;
        PrivateDevices = false;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        ReadOnlyPaths = [ modelsDir ] ++ optional (effective.source == "local") effective.modelPath;
        ReadWritePaths = [ "/var/lib/llama-cpp" ];
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        SupplementaryGroups = [ "render" ];
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service @resources"
          "~@privileged"
        ];
        UMask = "0077";
      };
    });

  portAssertions = mapAttrsToList
    (name: modelCfg:
      let
        effective = effectiveModel name modelCfg;
      in
      {
        assertion = effective.port != null;
        message = "infra.ai.inference.llamaCpp.models.${name}: port must be set.";
      })
    enabledModels;

  sourceAssertions = mapAttrsToList
    (name: modelCfg:
      let
        effective = effectiveModel name modelCfg;
      in
      if effective.source == "hf" then
        {
          assertion = effective.model != null && effective.modelPath == null;
          message = "infra.ai.inference.llamaCpp.models.${name}: source = \"hf\" requires model and forbids modelPath.";
        }
      else
        {
          assertion = effective.modelPath != null && effective.model == null;
          message = "infra.ai.inference.llamaCpp.models.${name}: source = \"local\" requires modelPath and forbids model.";
        })
    enabledModels;

  enabledPorts =
    builtins.map (modelCfg: (effectiveModel "unused" modelCfg).port) (attrValues enabledModels);
  openFirewallPorts =
    builtins.map (modelCfg: (effectiveModel "unused" modelCfg).port)
      (attrValues (filterAttrs (_: modelCfg: (effectiveModel "unused" modelCfg).openFirewall) enabledModels));
in
{
  options.infra.ai.inference.llamaCpp = {
    enable = mkEnableOption "declarative llama.cpp inference services";

    defaults = {
      package = mkOption {
        type = types.package;
        default = pkgs.llama-cpp;
        description = "Default llama.cpp package used by generated services.";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Default bind host for llama.cpp services.";
      };

      fit = mkOption {
        type = types.enum [ "auto" "on" "off" ];
        default = "off";
        description = "Default value passed to llama-server via -fit.";
      };

      ctxSize = mkOption {
        type = types.ints.positive;
        default = 4096;
        description = "Default context size for generated llama.cpp services.";
      };

      metrics = mkOption {
        type = types.bool;
        default = true;
        description = "Expose llama.cpp metrics by default.";
      };

      enableUnifiedMemory = mkOption {
        type = types.bool;
        default = true;
        description = "Export GGML_CUDA_ENABLE_UNIFIED_MEMORY=1 by default.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Whether generated services open their TCP port in the firewall by default.";
      };

      extraEnvironment = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Extra environment variables merged into every llama.cpp service.";
      };
    };

    models = mkOption {
      default = { };
      description = "Per-model llama.cpp service definitions.";
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          enable = mkEnableOption "llama.cpp model service";

          autoStart = mkOption {
            type = types.bool;
            default = false;
            description = "Whether this model is started automatically with multi-user.target.";
          };

          description = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Custom systemd description for this model service.";
          };

          source = mkOption {
            type = types.enum [ "hf" "local" ];
            default = "hf";
            description = "Model source kind: Hugging Face reference or a local GGUF path.";
          };

          model = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Hugging Face model reference used with llama-server -hf.";
          };

          modelPath = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Absolute local GGUF path used with llama-server --model.";
          };

          port = mkOption {
            type = types.nullOr types.port;
            default = null;
            description = "TCP port exposed by this llama.cpp service.";
          };

          package = mkOption {
            type = types.nullOr types.package;
            default = null;
            description = "Optional package override for this specific model service.";
          };

          host = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional bind host override for this specific model service.";
          };

          ctxSize = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
            description = "Optional context size override for this specific model service.";
          };

          fit = mkOption {
            type = types.nullOr (types.enum [ "auto" "on" "off" ]);
            default = null;
            description = "Optional -fit override for this specific model service.";
          };

          metrics = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "Optional metrics toggle for this specific model service.";
          };

          enableUnifiedMemory = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "Optional GGML_CUDA_ENABLE_UNIFIED_MEMORY override for this model service.";
          };

          openFirewall = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "Optional firewall exposure override for this model service.";
          };

          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Extra llama-server arguments appended after the generated defaults.";
          };

          extraEnvironment = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Extra environment variables added to this model service.";
          };
        };
      }));
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions =
        portAssertions
        ++ sourceAssertions
        ++ [
          {
            assertion = builtins.length enabledPorts == builtins.length (lib.unique enabledPorts);
            message = "infra.ai.inference.llamaCpp: enabled models must use unique TCP ports.";
          }
        ];

      environment.systemPackages =
        import ../../catalog/apps/llama-cpp.nix {
          inherit pkgs;
          llamaCppPackage = cfg.defaults.package;
        };

      users.groups.llama-cpp = { };

      # A dedicated service user keeps HF and llama.cpp caches persistent across
      # restarts. DynamicUser would make cache ownership brittle for on-demand
      # downloads and large model reuse.
      users.users.llama-cpp = {
        isSystemUser = true;
        group = "llama-cpp";
        extraGroups = [ "render" ];
        home = "/var/lib/llama-cpp";
        createHome = true;
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/llama-cpp 2750 llama-cpp render -"
        "d ${cacheRoot} 0750 llama-cpp llama-cpp -"
        "d ${hfCacheDir} 0750 llama-cpp llama-cpp -"
        "d ${llamaCacheDir} 0750 llama-cpp llama-cpp -"
        "d ${modelsDir} 2775 root render -"
      ];

      networking.firewall.allowedTCPPorts = openFirewallPorts;
    }

    {
      systemd.services = lib.mapAttrs' mkModelService enabledModels;
    }
  ]);
}

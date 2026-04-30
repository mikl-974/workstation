{ inputs, pkgs, ... }:
let
  llamaRocmPkgs = import inputs.nixpkgs-llama {
    system = pkgs.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
      rocmSupport = true;
    };
  };
in
{
  # Host-local capability map for `ms-s1-max`.
  #
  # This file is the authoritative place to answer:
  # "What does this machine have?"
  #
  # Keep the mapping explicit here even when it imports reusable bundles.
  imports = [
    ../../../../systems/containers/podman.nix
    ../../../../systems/bundles/dev-workstation.nix
    ../../../../systems/apps/podman-desktop.nix
    ../../../../systems/bundles/ai-local.nix
    ../../../../systems/bundles/gaming.nix
    ../../../../systems/bundles/rocm-runtime.nix
  ];

  # AnythingLLM is part of the intended workstation setup, but remains
  # installed through Flatpak until nixpkgs has a clean package for it:
  #   flatpak install flathub com.anythingllm.anythingllm

  nixpkgs.config.rocmSupport = true;

  # Strix Halo (gfx1151) is still not detected reliably by all ROCm consumers.
  # Keep the override global for manual llama.cpp/rocminfo sessions, and mirror
  # the service-specific part below for the Ollama daemon.
  environment.variables = {
    HSA_OVERRIDE_GFX_VERSION = "11.5.1";
    MIOPEN_DEBUG_DISABLE_FIND_DB = "1";
  };

  infra.ai.inference.llamaCpp = {
    enable = true;

    defaults = {
      package = llamaRocmPkgs.llama-cpp-rocm;
      host = "127.0.0.1";
      fit = "off";
      ctxSize = 4096;
      metrics = true;
      enableUnifiedMemory = true;
      openFirewall = false;
    };

    models = {
      qwen36-35b-a3b-q8 = {
        enable = true;
        autoStart = false;
        description = "Qwen3.6 35B A3B Q8_0 via llama.cpp";
        source = "hf";
        model = "unsloth/Qwen3.6-35B-A3B-GGUF:Q8_0";
        port = 8080;
        ctxSize = 4096;
        fit = "off";
        metrics = false;
        enableUnifiedMemory = false;
        extraArgs = [
          "--no-mmap"
          "--no-host"
          "--flash-attn"
          "on"
          "--parallel"
          "1"
          "--batch-size"
          "2048"
          "--ubatch-size"
          "2048"
        ];
      };

      gemma4-31b-q8 = {
        enable = true;
        autoStart = true;
        description = "Gemma 4 31B Q8_0 via llama.cpp";
        source = "hf";
        model = "unsloth/gemma-4-31B-it-GGUF:Q8_0";
        port = 8081;
        ctxSize = 4096;
        fit = "off";
        metrics = false;
        enableUnifiedMemory = false;
        extraArgs = [
          "--no-mmap"
          "--flash-attn"
          "on"
          "--parallel"
          "1"
          "--batch-size"
          "2048"
          "--ubatch-size"
          "2048"
        ];
      };

      qwen3-coder-next-q8 = {
        enable = true;
        autoStart = true;
        description = "Qwen3 Coder Next Q8_0 via llama.cpp";
        source = "hf";
        model = "unsloth/Qwen3-Coder-Next-GGUF:Q8_0";
        port = 8082;
        ctxSize = 4096;
        fit = "off";
        metrics = false;
        enableUnifiedMemory = false;
        extraArgs = [
          "--no-mmap"
          "--no-host"
          "--flash-attn"
          "on"
          "--parallel"
          "1"
          "--batch-size"
          "2048"
          "--ubatch-size"
          "2048"
        ];
      };
    };
  };

  workstation.containers.podman.enable = true;
}

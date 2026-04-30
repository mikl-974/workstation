{ inputs, pkgs, ... }:
let
  llamaPkgs = import inputs.nixpkgs-llama {
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
      package = llamaPkgs.llama-cpp-rocm;
      host = "127.0.0.1";
      fit = "off";
      ctxSize = 4096;
      metrics = true;
      enableUnifiedMemory = true;
      openFirewall = false;
    };

    models = {
      qwen36-27b-bf16 = {
        enable = true;
        autoStart = true;
        description = "Qwen3.6 27B BF16 via llama.cpp";
        source = "hf";
        model = "unsloth/Qwen3.6-27B-GGUF:BF16";
        port = 8080;
        ctxSize = 4096;
        fit = "off";
        metrics = false;
        enableUnifiedMemory = false;
        extraArgs = [
          "--no-mmap"
          "--flash-attn"
          "on"
          "--batch-size"
          "2048"
          "--ubatch-size"
          "2048"
        ];
      };

      gemma4 = {
        enable = true;
        autoStart = false;
        description = "Gemma 4 via llama.cpp";
        source = "hf";
        model = "ggml-org/gemma-4-E2B-it-GGUF";
        port = 8081;
        ctxSize = 8192;
        extraArgs = [ ];
      };
    };
  };

  workstation.containers.podman.enable = true;
}

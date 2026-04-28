{ pkgs, ... }:
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
    ../../../../systems/bundles/rocm-runtime.nix
  ];

  # AnythingLLM is part of the intended workstation setup, but remains
  # installed through Flatpak until nixpkgs has a clean package for it:
  #   flatpak install flathub com.anythingllm.anythingllm

  nixpkgs.config.rocmSupport = true;

  workstation.containers.podman.enable = true;

  # Set this if ROCm does not detect the GPU correctly.
  # Example for gfx1100-class cards:
  # services.ollama.rocmOverrideGfx = "11.0.0";
}

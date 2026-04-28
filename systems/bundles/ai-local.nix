{ ... }:
{
  imports = [
    ../apps/ollama-local.nix
    ../apps/llama-cpp.nix
    ../apps/opencode-desktop.nix
  ];

  services.flatpak.enable = true;
}

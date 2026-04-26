{ ... }:
{
  imports = [
    ./ollama-local.nix
    ./llama-cpp.nix
    ./opencode-desktop.nix
  ];

  services.flatpak.enable = true;
}

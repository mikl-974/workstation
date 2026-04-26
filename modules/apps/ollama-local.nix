{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    openFirewall = false;
    package = pkgs.ollama-rocm;
  };
}

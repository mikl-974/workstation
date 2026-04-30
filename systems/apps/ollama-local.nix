{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    openFirewall = false;
    package = pkgs.ollama-vulkan;
    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "10m";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
    };
  };
}

{ lib, config, ... }:
let
  cfg = config.infra.stacks.ai-server;
in
{
  options.infra.stacks.ai-server.enable =
    lib.mkEnableOption "local AI server stack (ollama service)";

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      openFirewall = false;
    };
  };
}

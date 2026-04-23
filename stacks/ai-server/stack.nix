{
  name = "ai-server";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "ollama" ];
  secrets = [ ];
  needs = [ ];
  volumes = [ "ollama-models" ];
}

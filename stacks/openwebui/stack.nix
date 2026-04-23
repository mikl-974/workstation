{
  name = "openwebui";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "llm-ui" ];
  secrets = [ "openwebui/token" ];
  needs = [ "llmBackend" ];
  volumes = [ "openwebui-data" ];
}

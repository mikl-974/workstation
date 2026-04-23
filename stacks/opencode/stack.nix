{
  name = "opencode";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "internal-service" ];
  secrets = [ "opencode/token" ];
  needs = [ "httpIngress" ];
  volumes = [ "opencode-data" ];
}

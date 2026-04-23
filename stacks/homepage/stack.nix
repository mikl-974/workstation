{
  name = "homepage";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "portal" ];
  secrets = [ "homepage/token" ];
  needs = [ "httpIngress" ];
  volumes = [ "homepage-config" ];
}

{
  name = "rustdesk";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "remote-access" ];
  secrets = [ "rustdesk/token" ];
  needs = [ "publicIngress" ];
  volumes = [ "rustdesk-data" ];
}

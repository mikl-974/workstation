{
  name = "n8n";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "automation" ];
  secrets = [ "n8n/token" ];
  needs = [ "persistentVolume" ];
  volumes = [ "n8n-data" ];
}

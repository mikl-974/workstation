{
  name = "uptime-kuma";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" "azureContainerApps" "gcpCloudRun" ];
  roles = [ "monitoring" ];
  secrets = [ "uptime-kuma/token" ];
  needs = [ "publicIngress" "persistentVolume" ];
  volumes = [ "uptime-kuma-data" ];
}

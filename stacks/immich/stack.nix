{
  name = "immich";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "app" "ml" ];
  secrets = [ "immich/token" ];
  needs = [ "postgres" "redis" "persistentVolume" ];
  volumes = [ "immich-data" ];
}

{
  name = "nextcloud";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "main" ];
  secrets = [
    "nextcloud/admin_password"
    "nextcloud/db_password"
    "nextcloud/redis_password"
  ];
  needs = [
    "postgres"
    "redis"
    "publicIngress"
    "persistentVolume"
  ];
  volumes = [
    "nextcloud-data"
    "nextcloud-db"
  ];
}

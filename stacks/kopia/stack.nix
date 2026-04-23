{
  name = "kopia";
  deploymentMode = "perTarget";
  supportedTargets = [ "nixosHost" ];
  roles = [ "backup-client" ];
  secrets = [ "kopia/token" ];
  needs = [ "objectStorageCredentials" ];
  volumes = [ "kopia-cache" ];
}

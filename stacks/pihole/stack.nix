{
  name = "pihole";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "dns" ];
  secrets = [ "pihole/token" ];
  needs = [ "lanAccess" ];
  volumes = [ "pihole-config" ];
}

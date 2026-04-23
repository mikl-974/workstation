{
  name = "tsdproxy";
  deploymentMode = "perTarget";
  supportedTargets = [ "nixosHost" ];
  roles = [ "edge-proxy" ];
  secrets = [ "tsdproxy/token" ];
  needs = [ "tailscaleAuth" ];
  volumes = [ ];
}

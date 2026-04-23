{
  name = "openclaw";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" ];
  roles = [ "gateway" ];
  secrets = [ "openclaw/env" ];
  needs = [ "tailscaleAuth" ];
  volumes = [ "openclaw-data" ];
}

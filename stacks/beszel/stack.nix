{
  name = "beszel";
  deploymentMode = "distributed";
  supportedTargets = [ "nixosHost" ];
  roles = [ "hub" "agent" ];
  secrets = [ "beszel/token" ];
  needs = [ "hubAgentConnectivity" ];
  volumes = [ "beszel-data" ];
}

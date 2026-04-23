{
  name = "keycloak";
  deploymentMode = "singleton";
  supportedTargets = [ "nixosHost" "azureContainerApps" ];
  roles = [ "identity-provider" ];
  secrets = [ "keycloak/token" ];
  needs = [ "postgres" "publicIngress" ];
  volumes = [ "keycloak-data" ];
}

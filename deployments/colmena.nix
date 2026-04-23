# Colmena hive — server-class NixOS hosts of this repo.
#
# Vendored shape from the previous `homelab` `deployments/colmena.nix`.
#
# Only `contabo` is exposed today: it is the only deployable server target in
# this repo. Workstations are installed via NixOS Anywhere and reconfigured
# locally with `nixos-rebuild`, not pushed via Colmena.
{ nixpkgs, colmena, flakeSelf }:
{
  meta = {
    nixpkgs = import nixpkgs { system = "x86_64-linux"; };
  };

  contabo = { ... }: {
    deployment.targetHost = "contabo";
    imports = [ (flakeSelf + "/targets/hosts/contabo/default.nix") ];
  };
}

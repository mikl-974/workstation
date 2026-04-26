# Colmena hive — server-class NixOS hosts of this repo.
#
# Only `contabo` is exposed today: it is the only deployable server target in
# this repo. Workstations are installed or reconfigured locally, not pushed
# via Colmena.
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

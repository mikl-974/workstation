{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/apps/datagrip.nix { inherit pkgs; };
}

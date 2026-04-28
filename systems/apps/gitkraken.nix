{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/apps/gitkraken.nix { inherit pkgs; };
}

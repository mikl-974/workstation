{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/apps/lutris.nix { inherit pkgs; };
}

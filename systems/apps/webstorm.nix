{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/apps/webstorm.nix { inherit pkgs; };
}

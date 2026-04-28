{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/bundles/desktop-apps.nix { inherit pkgs; };
}

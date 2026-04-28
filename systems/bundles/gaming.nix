{ pkgs, ... }:
{
  imports = [ ../apps/steam.nix ];

  environment.systemPackages = import ../../catalog/bundles/gaming.nix { inherit pkgs; };
}

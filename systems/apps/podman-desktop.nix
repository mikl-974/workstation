{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/apps/podman-desktop.nix { inherit pkgs; };
}

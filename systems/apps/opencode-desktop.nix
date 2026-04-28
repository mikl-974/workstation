{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/apps/opencode-desktop.nix { inherit pkgs; };
}

{ pkgs, ... }:
{
  programs.nix-ld.enable = true;

  environment.systemPackages = import ../../catalog/bundles/rider-workstation.nix { inherit pkgs; };
}

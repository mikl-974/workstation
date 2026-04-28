{ pkgs, ... }:
{
  imports = [ ../apps/neovim.nix ];

  environment.systemPackages = import ../../catalog/bundles/dev-workstation.nix { inherit pkgs; };
}

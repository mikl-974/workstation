{ pkgs, ... }:
{
  imports = [ ../apps/neovim.nix ];

  environment.systemPackages = import ../../catalog/bundles/dev.nix { inherit pkgs; };
}

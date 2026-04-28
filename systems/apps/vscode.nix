{ pkgs, ... }:
{
  environment.systemPackages = import ../../catalog/apps/vscode.nix { inherit pkgs; };
}

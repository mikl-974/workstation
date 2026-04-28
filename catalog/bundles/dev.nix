{ pkgs }:
  (import ./editors.nix { inherit pkgs; })
  ++ (import ../apps/gitkraken.nix { inherit pkgs; })

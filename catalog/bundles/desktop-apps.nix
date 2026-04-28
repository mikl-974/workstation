{ pkgs }:
  (import ./daily.nix { inherit pkgs; })
  ++ (import ./utilities.nix { inherit pkgs; })
  ++ (with pkgs; [
    xdg-utils
    file
    ripgrep
  ])

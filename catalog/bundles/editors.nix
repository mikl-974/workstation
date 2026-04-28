{ pkgs }:
  (import ../apps/vscode.nix { inherit pkgs; })
  ++ (import ./rider-workstation.nix { inherit pkgs; })
  ++ (import ../apps/webstorm.nix { inherit pkgs; })
  ++ (import ../apps/datagrip.nix { inherit pkgs; })

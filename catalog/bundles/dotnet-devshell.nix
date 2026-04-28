{ pkgs }:
  (import ../apps/dotnet-sdk.nix { inherit pkgs; })
  ++ (import ../apps/core-cli.nix { inherit pkgs; })
  ++ (import ../apps/tls-pki.nix { inherit pkgs; })
  ++ (import ../apps/docker-cli.nix { inherit pkgs; })
  ++ (import ../apps/playwright.nix { inherit pkgs; })

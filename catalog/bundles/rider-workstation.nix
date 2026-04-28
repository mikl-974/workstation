{ pkgs }:
  (import ../apps/rider.nix { inherit pkgs; })
  ++ (import ../apps/dotnet-sdks-workstation.nix { inherit pkgs; })
  ++ (import ../apps/protobuf-grpc.nix { inherit pkgs; })
  ++ (import ../apps/core-cli.nix { inherit pkgs; })
  ++ (import ../apps/tls-pki.nix { inherit pkgs; })

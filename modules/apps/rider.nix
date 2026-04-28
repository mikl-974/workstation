{ pkgs, ... }:
{
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    jetbrains.rider

    # .NET SDK — main runtime and build toolchain
    (pkgs.dotnetCorePackages.combinePackages [
        pkgs.dotnetCorePackages.sdk_10_0
        pkgs.dotnetCorePackages.sdk_9_0
      ])

    # Protobuf / gRPC — utile pour éviter les binaires NuGet non compatibles NixOS
    protobuf
    grpc

    # Version control and HTTP utilities
    git
    curl
    jq

    # TLS / PKI
    openssl
    pkg-config
  ];
}

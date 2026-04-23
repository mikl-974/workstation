# Workstation .NET development shell.
#
# This shell is local to workstation — it is NOT a generic shared primitive.
# It is the CLI and runtime environment for .NET development on this workstation.
#
# Scope: CLI tooling and runtimes only.
# IDEs (VS Code, Rider, WebStorm) are desktop applications — they live in
# modules/apps/editors.nix and are installed via profiles/dev.nix.
#
# Personal dev workstation tooling belongs in this repo. It is intentionally
# kept inside `infra/modules/devshells/` rather than abstracted out: there is
# no second consumer that would justify a shared layer.
{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    # .NET SDK — main runtime and build toolchain
    dotnet-sdk

    # Version control and HTTP utilities
    git
    curl
    jq

    # TLS / PKI
    openssl
    pkg-config

    # Container tooling — Docker CLI (daemon managed separately by the host OS)
    docker-client

    # Browser automation testing
    playwright
  ];
}

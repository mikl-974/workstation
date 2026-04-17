# Workstation .NET development shell.
#
# This shell is local to workstation — it is NOT a generic shared primitive.
# It represents the actual personal dev environment for this workstation:
# IDEs (Rider, WebStorm), Docker, and supporting CLI tooling live here.
#
# Do not move this to foundation. foundation hosts generic, server-side
# reusable modules. A personal dev workstation shell belongs here.
#
# Extension path:
#   - Rider / WebStorm: uncomment jetbrains.rider / jetbrains.webstorm below
#   - Node: add nodejs, npm
#   - Local web dev: add caddy, mkcert, httpie
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

    # Editor — lightweight IDE for quick edits and web work
    vscode

    # Rider and WebStorm: heavy IDEs — uncomment when needed.
    # They are packaged in nixpkgs and can be added here at any time.
    # jetbrains.rider
    # jetbrains.webstorm
  ];
}

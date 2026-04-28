# Workstation .NET development shell.
#
# This shell is local to workstation — it is NOT a generic shared primitive.
# It is the CLI and runtime environment for .NET development on this workstation.
#
# Scope: CLI tooling and runtimes only.
# IDEs (VS Code, Rider, WebStorm) are desktop applications — they live in
# systems/bundles/editors.nix and are installed as system packages on the
# workstation.
#
# Personal dev workstation tooling belongs in this repo. It is intentionally
# kept inside `infra/`, but now reuses the shared package catalog so shell and
# NixOS package wrappers don't fork their package lists.
{ pkgs }:
pkgs.mkShell {
  packages = import ../../catalog/bundles/dotnet-devshell.nix { inherit pkgs; };
}

{ pkgs, ... }:
{
  # Editors and IDEs are desktop applications — they are NOT part of the devShell.
  # The devShell provides the CLI/runtime environment; editors are separate tools
  # that work alongside it.
  #
  # This module is imported by profiles/dev.nix so that editors are available
  # on any host that opts into the dev profile.
  environment.systemPackages = with pkgs; [
    # Lightweight editor / general web and scripting work
    vscode

    # .NET / C# IDE — full IDE for .NET projects
    jetbrains.rider

    # JavaScript / TypeScript / frontend IDE
    jetbrains.webstorm
  ];
}

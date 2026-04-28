{ pkgs, ... }:
{
  # Editors and IDEs are desktop applications — they are NOT part of the devShell.
  # The devShell provides the CLI/runtime environment; editors are separate tools
  # that work alongside it.
  #
  # This file is now a bundle wrapper around the shared package catalog.
  imports = [
    ../apps/neovim.nix
  ];

  environment.systemPackages = import ../../catalog/bundles/editors.nix { inherit pkgs; };
}

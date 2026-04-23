{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Editors and IDEs are desktop applications — they are NOT part of the devShell.
  # The devShell provides the CLI/runtime environment; editors are separate tools
  # that work alongside it.
  #
  # This module is imported by modules/profiles/dev.nix so that editors are available
  # on any host that opts into the dev profile.
  # These packages come from the main `pkgs`, which already tracks nixos-unstable.
  environment.systemPackages = with pkgs; [
    # Lightweight editor / general web and scripting work
    vscode
    jetbrains.rider
    jetbrains.webstorm
  ];
}

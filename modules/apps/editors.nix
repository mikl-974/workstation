{ ... }:
{
  # Editors and IDEs are desktop applications — they are NOT part of the devShell.
  # The devShell provides the CLI/runtime environment; editors are separate tools
  # that work alongside it.
  #
  # This file is now a bundle made from atomic app modules.
  imports = [
    ./neovim.nix
    ./vscode.nix
    ./rider.nix
    ./webstorm.nix
  ];
}

{ ... }:
{
  imports = [
    ./noctalia.nix
  ];
  # Package installation is handled by noctalia.nix when the option is enabled.
  # Do not duplicate packages here — add them in the appropriate sub-module.
}

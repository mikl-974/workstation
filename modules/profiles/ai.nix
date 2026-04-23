{ ... }:
{
  # AI profile — assembles the local AI role for a desktop workstation host.
  # Import this profile in hosts where local AI tooling is desired.
  #
  # Scope: personal, local use only. No shared services, no server exposure.
  # See docs/ai.md for details and the distinction with stacks/ai-server.
  #
  # Requires: modules/profiles/desktop-hyprland.nix (hardware.graphics for GPU inference)
  imports = [
    ../roles/ai.nix
  ];
}

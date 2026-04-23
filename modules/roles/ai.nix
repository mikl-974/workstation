{ ... }:
{
  # AI local role — personal AI tooling for a user workstation.
  #
  # This role is:
  #   - for user workstations, NOT servers
  #   - local inference and desktop tooling only
  #   - no shared network services, no multi-machine exposure
  #   - user-managed processes, not system daemons
  #
  # Distinction from infra ai-server stack:
  #   local user ai    — tools the user runs locally on their own machine
  #   stacks/ai-server — shared inference service exposed to other machines
  #
  # The ollama CLI is available after enabling this role. Start it manually:
  #   ollama serve          (starts local API on localhost:11434)
  #   ollama pull llama3    (download a model)
  #   ollama run llama3     (interactive chat)
  #
  # AnythingLLM Desktop is not yet available in nixpkgs. Install it via Flatpak:
  #   flatpak install flathub com.anythingllm.anythingllm
  # Flatpak support is enabled below.

  imports = [
    ../apps/ai.nix
  ];

  # Flatpak: required for AnythingLLM Desktop (not yet in nixpkgs).
  # This also allows installing other desktop AI tools from Flathub.
  services.flatpak.enable = true;
}

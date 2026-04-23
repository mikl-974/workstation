{ pkgs, ... }:
{
  # Desktop developer applications that are not editors/IDEs.
  #
  # Scope:
  #   - GUI development tools used directly on the workstation
  #   - no container/runtime backend logic here
  #   - no VPN / networking service logic here
  environment.systemPackages = with pkgs; [
    # Git GUI client for repository review, history navigation, and merge work
    gitkraken
  ];
}

{ pkgs, ... }:
{
  # Daily desktop applications — end-user apps used routinely on the workstation.
  #
  # Scope:
  #   - browser
  #   - document and image viewing
  #   - file and archive browsing
  #   - explicit desktop comfort apps kept as user-facing applications
  #
  # Out of scope:
  #   - technical/system helpers -> modules/apps/utilities.nix
  #   - desktop/system integration -> modules/desktop/
  #   - editors and IDEs -> host-local capability maps when needed
  #   - specialized AI/dev tooling -> host-local capability maps
  environment.systemPackages = with pkgs; [
    # Web browser
    firefox
    chromium

    # PDF / document viewer
    zathura

    # Lightweight image viewer
    imv

    # File and archive browsing
    thunar
    file-roller

    # Explicit desktop comfort apps
    cliphist
    localsend
    mako
    wofi
  ];
}

{ ... }:
{
  imports = [
    ../desktop/default.nix
    ../bundles/desktop-apps.nix
    ../shell/default.nix
    ../theming/default.nix
  ];

  # Cloudflare WARP: desktop-only VPN client. Kept in workstation because
  # it is a user-facing network tool, not a generic infrastructure primitive.
  workstation.desktop.warp.enable = true;

  # Noctalia is the desktop shell used on this workstation.
  # The actual shell settings live in Home Manager via home/roles/noctalia.nix.
  workstation.theming.noctalia.enable = true;
}

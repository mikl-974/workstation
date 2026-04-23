{ ... }:
{
  imports = [
    ../desktop/default.nix
    ../apps/default.nix
    ../shell/default.nix
    ../theming/default.nix
  ];

  # Cloudflare WARP: desktop-only VPN client. Kept in workstation because
  # it is a user-facing network tool, not a generic infrastructure primitive.
  workstation.desktop.warp.enable = true;

  # Noctalia: personal color scheme and visual identity of this workstation.
  workstation.theming.noctalia.enable = true;
}

# Home Manager composition for the concrete target `gaming`.
#
# This host stays intentionally mono-user: one normalized user identity, the
# shared Hyprland desktop role, and the explicit gaming user role used on this
# machine.
{
  mikl = {
    imports = [
      ../users/mikl.nix
      ../roles/desktop-hyprland.nix
      ../roles/gaming-steam.nix
    ];
  };
}

# Home Manager composition for the concrete target `main`.
#
# This host is intentionally simple for now: one real user, one reusable desktop
# role, and one explicit target composition.
{
  mikl = {
    imports = [
      ../users/mikl.nix
      ../roles/desktop-hyprland.nix
    ];
  };
}

# Home Manager composition for the concrete target `laptop`.
#
# This host is a simple mono-user target: one normalized user identity and one
# reusable desktop role in one explicit target composition.
{
  mikl = {
    imports = [
      ../users/mikl.nix
      ../roles/desktop-hyprland.nix
    ];
  };
}

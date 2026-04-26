# Checklist d'installation

## `contabo`

- [ ] `targets/hosts/contabo/vars.nix` correct
- [ ] disque cible confirme
- [ ] `nix run .#doctor -- --host contabo`
- [ ] `nix run .#validate-install -- contabo`
- [ ] acces SSH root disponible pour NixOS Anywhere

## `ms-s1-max`

- [ ] `targets/hosts/ms-s1-max/vars.nix` correct
- [ ] `nix run .#doctor -- --host ms-s1-max`
- [ ] `nix run .#validate-install -- ms-s1-max`
- [ ] reconfiguration locale ou installation manuelle preparee

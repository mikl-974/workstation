# Placement des briques dans `infra`

## Règle générale

- `modules/` : logique réutilisable
- `targets/hosts/` : machines concrètes
- `stacks/` : services/applications
- `home/` : composition utilisateur
- `dotfiles/` : contenu brut applicatif

## Exemples de placement

| Brique | Emplacement |
|---|---|
| Hyprland système | `modules/desktop/` + `modules/profiles/` |
| Steam / gaming système | `modules/roles/` + `modules/profiles/` |
| `ai-server` | `stacks/ai-server/` |
| binding user/browser/terminal | `home/roles/` + `home/targets/` |
| fichiers Hyprland / Kitty / Wofi / Mako | `dotfiles/` |
| secrets chiffrés | `secrets/` via `sops-nix` |

## Cas NordVPN

NordVPN reste une capacité visée côté machine, mais n'est pas encodé en Nix tant qu'il n'existe pas de support upstream propre dans la base retenue.

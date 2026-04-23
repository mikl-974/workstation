# modules/

Briques Nix réutilisables composées dans les targets et profils.

## Règle

Ce dossier contient uniquement :
- modules NixOS réutilisables
- modules Darwin réutilisables
- profils réutilisables
- devshells
- templates
- helpers et lib

Il ne contient jamais :
- de machine concrète
- de stack applicative
- de logique d'installation spécifique à une machine

## Structure

| Dossier | Rôle |
|---|---|
| `modules/apps/` | Paquets et applications desktop |
| `modules/containers/` | Moteurs de containers locaux |
| `modules/darwin/` | Base et intégrations Darwin (`nix-darwin`, `nix-homebrew`) |
| `modules/desktop/` | Base système desktop (Hyprland, audio, connectivité) |
| `modules/devshells/` | Environnements de développement CLI |
| `modules/profiles/` | Assemblages réutilisables (composés dans les targets, ex. `virtual-machine.nix`) |
| `modules/roles/` | Composition d'apps + config système pour un usage |
| `modules/security/` | Intégrations sécurité réutilisables (`sops-nix`) |
| `modules/shell/` | Configuration shell système |
| `modules/theming/` | Theming et identité visuelle |
| `modules/templates/` | Templates de configuration |

# systems/

Briques Nix reutilisables du repo.

## Dossiers principaux

- `catalog/` : catalogue mutualise de paquets atomiques et de bundles reutilisables
- `systems/apps/` : apps atomiques ou capacites unitaires
- `systems/bundles/` : compositions reutilisables de plusieurs apps ou paquets
- `systems/containers/` : moteurs de containers locaux
- `systems/darwin/` : base Darwin
- `systems/desktop/` : base desktop NixOS
- `systems/devshells/` : points d'entree `mkShell` des environnements de dev CLI
- `systems/dokploy/` : preparation serveur Dokploy
- `systems/networking/` : reseau reutilisable
- `systems/profiles/` : profils publics importes par les hosts
- `systems/security/` : securite reutilisable
- `systems/shell/` : shell systeme
- `systems/theming/` : theming
- `systems/users/` : users systeme

## Profils actifs

- `workstation-common.nix`
- `server.nix`
- `gaming.nix`

Le reste de la cartographie logicielle doit rester visible dans les hosts.
Exemple :

- `targets/hosts/ms-s1-max/config/capabilities.nix`

## Regle de composition

Le repo retient maintenant cette hierarchie :

- `catalog/apps/<app>.nix` : liste de paquets mutualisee pour une brique atomique
- `catalog/bundles/<bundle>.nix` : composition mutualisee de listes de paquets
- `systems/apps/<app>.nix` : app ou capacite atomique
- `systems/bundles/<bundle>.nix` : bundle applicatif compose de plusieurs apps
- `systems/devshells/<shell>.nix` : point d'entree `mkShell` qui assemble le catalogue
- `systems/profiles/<profile>.nix` : profil reutilisable quand le bundle a un vrai sens de composition

Exemple retenu :

- `systems/apps/lutris.nix` : installer Lutris seul
- `systems/apps/steam.nix` : installer Steam seul
- `systems/bundles/gaming.nix` : pack gaming compose
- `systems/profiles/gaming.nix` : point d'entree reutilisable si un host veut le bundle complet
- `systems/apps/rider.nix` : installer Rider seul
- `systems/apps/webstorm.nix` : installer WebStorm seul
- `systems/bundles/dev-workstation.nix` : bundle dev de workstation
- `systems/bundles/ai-local.nix` : bundle IA locale
- `systems/devshells/dotnet.nix` : shell CLI qui reconsomme `catalog/bundles/dotnet-devshell.nix`

Donc :

- une app peut rester installable independamment
- un profil n'existe que quand "tout ou rien" a un vrai sens operatoire
- un host peut importer un bundle tout en gardant sa carte logicielle visible

# modules/

Briques Nix reutilisables du repo.

## Dossiers principaux

- `catalog/` : catalogue mutualise de paquets atomiques et de bundles reutilisables
- `modules/apps/` : apps atomiques ou capacites unitaires
- `modules/bundles/` : compositions reutilisables de plusieurs apps ou paquets
- `modules/containers/` : moteurs de containers locaux
- `modules/darwin/` : base Darwin
- `modules/desktop/` : base desktop NixOS
- `modules/devshells/` : points d'entree `mkShell` des environnements de dev CLI
- `modules/dokploy/` : preparation serveur Dokploy
- `modules/networking/` : reseau reutilisable
- `modules/profiles/` : profils publics importes par les hosts
- `modules/security/` : securite reutilisable
- `modules/shell/` : shell systeme
- `modules/theming/` : theming
- `modules/users/` : users systeme

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
- `modules/apps/<app>.nix` : app ou capacite atomique
- `modules/bundles/<bundle>.nix` : bundle applicatif compose de plusieurs apps
- `modules/devshells/<shell>.nix` : point d'entree `mkShell` qui assemble le catalogue
- `modules/profiles/<profile>.nix` : profil reutilisable quand le bundle a un vrai sens de composition

Exemple retenu :

- `modules/apps/lutris.nix` : installer Lutris seul
- `modules/apps/steam.nix` : installer Steam seul
- `modules/bundles/gaming.nix` : pack gaming compose
- `modules/profiles/gaming.nix` : point d'entree reutilisable si un host veut le bundle complet
- `modules/apps/rider.nix` : installer Rider seul
- `modules/apps/webstorm.nix` : installer WebStorm seul
- `modules/bundles/dev-workstation.nix` : bundle dev de workstation
- `modules/bundles/ai-local.nix` : bundle IA locale
- `modules/devshells/dotnet.nix` : shell CLI qui reconsomme `catalog/bundles/dotnet-devshell.nix`

Donc :

- une app peut rester installable independamment
- un profil n'existe que quand "tout ou rien" a un vrai sens operatoire
- un host peut importer un bundle tout en gardant sa carte logicielle visible

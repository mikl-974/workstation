# Daily apps

## Objectif

La couche `daily apps` regroupe les applications desktop de base utilisees au quotidien sur la workstation.

Elle existe pour eviter de melanger :

- les apps utilisateur courantes
- les utilitaires techniques
- la connectivite desktop
- les IDE
- les roles specialises (`gaming`, `ai`)

## Localisation

La couche vit dans :

- `modules/apps/daily.nix`

Elle est composee automatiquement dans la base desktop via :

- `modules/apps/default.nix`
- `modules/profiles/desktop-hyprland.nix`

## Contenu actuel

Applications retenues :

| App | Rôle |
|---|---|
| `firefox` | navigateur web generaliste |
| `chromium` | navigateur secondaire / compatibilite web |
| `zathura` | visionneuse PDF |
| `imv` | visionneuse d'images legere |
| `thunar` | gestionnaire de fichiers |
| `file-roller` | gestionnaire d'archives |
| `localsend` | partage local de fichiers entre appareils utilisateur |
| `cliphist` | historique du presse-papiers |
| `mako` | notifications desktop Wayland |

Ces paquets sont installes explicitement comme apps desktop.
Quand une integration UX est necessaire, elle est declaree explicitement dans les dotfiles actifs et liee par Home Manager.
Voir `docs/first-boot.md` pour l'integration actuelle de `mako` et `cliphist`.

## Pourquoi ces apps sont dans `daily.nix`

Ces applications correspondent a l'usage courant de la machine :

- ouvrir le web
- lire un PDF
- visualiser une image
- parcourir des fichiers
- ouvrir une archive
- disposer d'un minimum de confort desktop explicite

Elles ne sont pas des aides techniques systeme.

## Frontieres

### Ce qui va dans `daily.nix`

- applications utilisateur courantes
- apps lancees directement pour un usage quotidien
- base desktop raisonnable et limitee

### Ce qui ne va pas dans `daily.nix`

- outils techniques comme `pavucontrol`, `brightnessctl`, `playerctl`, `nm-connection-editor` -> `modules/apps/utilities.nix`
- Bluetooth, Wi-Fi, NetworkManager, Solaar -> `modules/desktop/connectivity.nix`
- IDE et editeurs -> `modules/apps/editors.nix`
- gaming -> `modules/apps/gaming.nix`
- IA locale -> `modules/apps/ai.nix`

## Integration

La composition retenue est :

1. `modules/desktop/` -> base systeme desktop
2. `modules/apps/daily.nix` -> apps quotidiennes
3. `modules/apps/utilities.nix` -> helpers techniques
4. `modules/apps/editors.nix` -> outils dev desktop optionnels
5. `modules/profiles/desktop-hyprland.nix` -> point d'entree simple pour les hosts

Les hosts n'ont rien a assembler manuellement de plus.

## Ajouter une nouvelle daily app proprement

Avant d'ajouter un paquet a `daily.nix`, verifier :

1. est-ce une application utilisateur courante ?
2. est-ce distinct d'un outil technique ?
3. est-ce distinct d'un IDE ou d'un role specialise ?
4. est-ce vraiment utile sur tous les desktops qui importent la base ?

Si la reponse n'est pas clairement oui, l'app n'a probablement pas sa place ici.

## Eviter le fourre-tout

Regles simples :

- garder une base petite et evidente
- privilegier les apps transverses et vraiment quotidiennes
- ne pas y mettre des outils occasionnels ou specialises
- ne pas utiliser `daily.nix` comme tiroir par defaut

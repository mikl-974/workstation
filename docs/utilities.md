# Utilities desktop

## Objectif

Ajouter une couche claire de logiciels utilitaires et de connectivite locale pour une workstation desktop, sans melanger :

- les applications quotidiennes
- les paquets applicatifs
- la configuration systeme desktop
- les profils
- les hosts

## Structure retenue

Deux briques complementaires :

| Couche | Fichier | Rôle |
|---|---|---|
| Bundle utilitaires | `systems/bundles/utilities.nix` | petits outils desktop lances par l'utilisateur |
| Connectivite desktop | `systems/desktop/connectivity.nix` | Bluetooth, Wi-Fi/NetworkManager, applets et integration Logitech |

Cette separation suit l'architecture du repo :

- `systems/bundles/daily.nix` = applications quotidiennes
- `systems/apps/` = apps atomiques
- `systems/bundles/` = lots coherents
- `systems/desktop/` = configuration systeme desktop
- `profiles/desktop-hyprland.nix` = composition

## Contenu

### `systems/bundles/utilities.nix`

Paquets installes :

| Paquet | Rôle |
|---|---|
| `pavucontrol` | mixer audio / helper technique desktop |
| `nm-connection-editor` | edition avancee des connexions NetworkManager |
| `brightnessctl` | controle de luminosite |
| `playerctl` | controle des lecteurs multimedia |

Ces paquets sont des **helpers techniques desktop**.
Les applications de base de l'utilisateur (navigateur, PDF, images, fichiers, archives) vivent dans `systems/bundles/daily.nix`.

### `systems/desktop/connectivity.nix`

Configuration systeme :

| Option | Rôle |
|---|---|
| `networking.networkmanager.enable = true` | pile reseau desktop locale |
| `programs.nm-applet.enable = true` | applet NetworkManager |
| `hardware.bluetooth.enable = true` | pile Bluetooth systeme |
| `hardware.bluetooth.powerOnBoot = true` | Bluetooth pret au boot |
| `services.blueman.enable = true` | gestionnaire Bluetooth desktop |
| `hardware.logitech.wireless.enable = true` | support Logitech + regles udev |
| `hardware.logitech.wireless.enableGraphical = true` | Solaar graphique |

## Solaar

Solaar est traite comme un outil de poste utilisateur, mais son activation passe par :

```nix
hardware.logitech.wireless.enable = true;
hardware.logitech.wireless.enableGraphical = true;
```

Pourquoi ce choix :

- Solaar a besoin des regles udev Logitech
- ce besoin est gere proprement par le module NixOS `hardware.logitech.wireless.*`
- un simple `environment.systemPackages = [ pkgs.solaar ]` serait incomplet

Conclusion :

- **Solaar reste dans `infra`**
- **il n'est pas extrait vers un repo partage**
- **il vit dans `systems/desktop/connectivity.nix` parce qu'il est couple au support systeme des peripheriques**

## Bluetooth

Le support Bluetooth desktop est structure ainsi :

- pile systeme : `hardware.bluetooth.enable`
- experience desktop : `services.blueman.enable`

La logique reste dans `systems/desktop/connectivity.nix`, pas dans les hosts.

## Wi-Fi / NetworkManager

La couche Wi-Fi / connectivite locale est structuree ainsi :

- base reseau locale : `networking.networkmanager.enable`
- applet desktop : `programs.nm-applet.enable`
- outil d'edition avancee : `nm-connection-editor`

Tailscale reste separe dans `profiles/networking.nix` via le module local `systems/networking/tailscale.nix`.

## Frontiere desktop / reseau

Ce qui reste dans `systems/networking/` (briques reseau systeme reutilisables) :

- les briques reseau generiques et partageables (ex. Tailscale)

Ce qui reste dans `systems/desktop/`, `systems/apps/` et `systems/bundles/` (couche desktop utilisateur) :

- les daily apps desktop
- les applets desktop
- Bluetooth cote utilisateur
- Solaar
- les outils d'edition de connexions locales

Regle :

- si c'est une primitive reseau systeme reutilisable → `systems/networking/`
- si c'est lie au bureau utilisateur et a la machine locale → `systems/desktop/`, `systems/apps/` ou `systems/bundles/`

## Extension propre

Pour ajouter un nouvel utilitaire :

1. si c'est une application quotidienne de base bundlee → `systems/bundles/daily.nix`
2. si c'est un helper technique desktop bundle → `systems/bundles/utilities.nix`
3. si c'est une app atomique installable seule → `systems/apps/<app>.nix`
4. si c'est une integration systeme desktop → `systems/desktop/connectivity.nix` ou un autre module desktop cible
5. ne pas le mettre dans un host
6. ne pas le disperser entre `shell/`, `profiles/` et `dotfiles/` sans raison

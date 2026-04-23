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
| Apps utilitaires | `modules/apps/utilities.nix` | petits outils desktop lances par l'utilisateur |
| Connectivite desktop | `modules/desktop/connectivity.nix` | Bluetooth, Wi-Fi/NetworkManager, applets et integration Logitech |

Cette separation suit l'architecture du repo :

- `modules/apps/daily.nix` = applications quotidiennes
- `modules/apps/` = paquets
- `modules/desktop/` = configuration systeme desktop
- `profiles/desktop-hyprland.nix` = composition

## Contenu

### `modules/apps/utilities.nix`

Paquets installes :

| Paquet | Rôle |
|---|---|
| `pavucontrol` | mixer audio / helper technique desktop |
| `nm-connection-editor` | edition avancee des connexions NetworkManager |
| `brightnessctl` | controle de luminosite |
| `playerctl` | controle des lecteurs multimedia |

Ces paquets sont des **helpers techniques desktop**.
Les applications de base de l'utilisateur (navigateur, PDF, images, fichiers, archives) vivent dans `modules/apps/daily.nix`.

### `modules/desktop/connectivity.nix`

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

- **Solaar reste dans `workstation`**
- **il ne va pas dans `foundation`**
- **il vit dans `modules/desktop/connectivity.nix` parce qu'il est couple au support systeme des peripheriques**

## Bluetooth

Le support Bluetooth desktop est structure ainsi :

- pile systeme : `hardware.bluetooth.enable`
- experience desktop : `services.blueman.enable`

La logique reste dans `modules/desktop/connectivity.nix`, pas dans les hosts.

## Wi-Fi / NetworkManager

La couche Wi-Fi / connectivite locale est structuree ainsi :

- base reseau locale : `networking.networkmanager.enable`
- applet desktop : `programs.nm-applet.enable`
- outil d'edition avancee : `nm-connection-editor`

Tailscale reste separe dans `profiles/networking.nix` via `foundation`.

## Frontiere avec `foundation`

Ce qui reste dans `foundation` :

- les briques reseau generiques et partageables (ex. Tailscale)

Ce qui reste dans `workstation` :

- les daily apps desktop
- les applets desktop
- Bluetooth cote utilisateur
- Solaar
- les outils d'edition de connexions locales

Regle :

- si c'est generique, multi-contexte et partageable → `foundation`
- si c'est lie au bureau utilisateur et a la machine locale → `workstation`

## Extension propre

Pour ajouter un nouvel utilitaire :

1. si c'est une application quotidienne de base → `modules/apps/daily.nix`
2. si c'est un helper technique desktop → `modules/apps/utilities.nix`
3. si c'est une integration systeme desktop → `modules/desktop/connectivity.nix` ou un autre module desktop cible
4. ne pas le mettre dans un host
5. ne pas le disperser entre `shell/`, `profiles/` et `dotfiles/` sans raison

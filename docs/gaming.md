# Rôle Gaming

## Objectif

Le rôle `gaming` prépare un environnement de bureau orienté jeu sur une machine utilisateur NixOS.

Ce rôle est :
- réservé aux postes de travail (desktop), pas aux serveurs
- dépendant d'un environnement graphique (`modules/profiles/desktop-hyprland.nix`)
- composable avec d'autres profils sur le même host

## Contenu

### `modules/apps/gaming.nix`

Paquets installés au niveau système :

| Paquet | Rôle |
|---|---|
| `mangohud` | Overlay in-game (FPS, GPU, CPU, frametime) |
| `gamescope` | Micro-compositeur (scaling résolution, cap FPS) |
| `lutris` | Lanceur multi-plateformes (GOG, Epic, itch.io, scripts Battle.net) |
| `wineWow64` | Wine 64+32 bits — requis par Lutris et les lanceurs Wine |
| `winetricks` | Installeur de dépendances Wine (VC runtimes, DirectX, codecs) |
| `bottles` | Gestionnaire d'environnements Wine sandboxés — chemin recommandé pour Battle.net |

### `modules/roles/gaming.nix`

Configuration système composée :

- `programs.steam.enable = true` — intégration NixOS-native avec support Proton
- `programs.steam.gamescopeSession.enable = true` — session Steam dans gamescope
- `programs.gamemode.enable = true` — gouverneur de performance à la demande

### `modules/profiles/gaming.nix`

Point d'entrée profil : importe `modules/roles/gaming.nix`.

## Utilisation

Dans un host :

```nix
# targets/hosts/<name>/default.nix
imports = [
  ../../modules/profiles/desktop-hyprland.nix
  ../../modules/profiles/gaming.nix
  ../../modules/profiles/networking.nix
];
```

## Battle.net

Battle.net n'a pas de client Linux natif. Deux approches réalistes :

### Via Bottles (recommandé)

1. Ouvrir Bottles
2. Créer une bouteille de type "Gaming"
3. Installer Battle.net depuis l'interface Bottles

### Via Lutris

1. Aller sur [lutris.net](https://lutris.net) et chercher "Battle.net"
2. Utiliser le script d'installation Lutris officiel

## Proton et compatibilité Steam

Proton est géré directement depuis Steam → Paramètres → Steam Play.

Recommandation : activer "Steam Play pour tous les titres" et utiliser Proton-GE via ProtonUp-Qt (à installer manuellement).

## Gamemode

`gamemode` permet aux jeux de demander un profil de performance élevé (CPU governor, GPU tweaks).

Aucune configuration manuelle n'est requise — les jeux qui supportent gamemode l'activent automatiquement. Pour lancer un jeu avec gamemode manuellement :

```bash
gamemoderun %command%
# ou dans les options de lancement Steam : gamemoderun %command%
```

## Extension

Pour ajouter des outils gaming supplémentaires :

1. Ajouter les paquets dans `modules/apps/gaming.nix`
2. Ajouter la configuration système dans `modules/roles/gaming.nix` si nécessaire
3. Ne pas mettre de logique gaming directement dans `modules/profiles/gaming.nix` ou dans un host

## Relation avec le host `gaming`

Le target `targets/hosts/gaming/` est la machine physique dédiée au jeu.
Il importe `modules/profiles/gaming.nix` parmi ses profils.
La configuration machine (username, hostname, disque) reste dans `targets/hosts/gaming/vars.nix`.

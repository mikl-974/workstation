# DevShell .NET

## Pourquoi ce shell existe

Le shell `dotnet` fournit une base de poste de travail reproductible pour développer des projets .NET sans mélanger cet usage avec le shell par défaut du repo.

## Comment y entrer

```bash
nix develop .#dotnet
```

## Ce qu'il contient

Le point d'entree shell reste `systems/devshells/dotnet.nix`, mais son contenu
vient maintenant du bundle `catalog/bundles/dotnet-devshell.nix`, lui-meme
compose de briques atomiques dans `catalog/apps/`.

## Où il vit

- `catalog/apps/` : briques CLI atomiques mutualisees.
- `catalog/bundles/dotnet-devshell.nix` : composition reutilisable du shell .NET.
- `systems/devshells/dotnet.nix` : définition finale du shell .NET.
- `flake.nix` : exposition via `devShells.<system>.dotnet` (cf. `docs/devshells.md`).

## Comment l'étendre proprement

- ajouter un outil seulement s'il répond à un besoin récurrent du développement .NET ;
- garder les dépendances spécifiques à un projet **dans le projet lui-même** quand c'est possible (par exemple via un `shell.nix` local au projet) ;
- créer plus tard d'autres shells dédiés (`ops`, `desktop`, `tofu`) avec leurs briques dans `catalog/apps/` et leurs bundles dans `catalog/bundles/`, plutôt que de surcharger celui-ci.

## Ce qu'il ne doit pas devenir

- un shell universel pour tout le repo (pour ça, le shell par défaut `nix develop` suffit) ;
- un conteneur de tooling ops (Colmena, OpenTofu, etc., qui sont déjà exposés en `nix run .#...` et n'ont pas besoin d'un shell) ;
- un shell avec des dépendances lourdes non justifiées par le développement .NET.

Voir aussi `docs/devshells.md` pour la liste complète des shells exposés.

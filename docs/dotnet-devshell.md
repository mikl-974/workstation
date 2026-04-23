# DevShell .NET

## Pourquoi ce shell existe

Le shell `dotnet` fournit une base de poste de travail reproductible pour développer des projets .NET sans mélanger cet usage avec le shell par défaut du repo.

## Comment y entrer

```bash
nix develop .#dotnet
```

## Ce qu'il contient

Le périmètre exact est défini dans `modules/devshells/dotnet.nix`. Il reste volontairement réduit pour couvrir le développement .NET courant sans transformer le shell en environnement fourre-tout.

## Où il vit

- `modules/devshells/dotnet.nix` : définition du shell .NET.
- `flake.nix` : exposition via `devShells.<system>.dotnet` (cf. `docs/devshells.md`).

## Comment l'étendre proprement

- ajouter un outil seulement s'il répond à un besoin récurrent du développement .NET ;
- garder les dépendances spécifiques à un projet **dans le projet lui-même** quand c'est possible (par exemple via un `shell.nix` local au projet) ;
- créer plus tard d'autres shells dédiés (`ops`, `desktop`, `tofu`) dans `modules/devshells/` plutôt que de surcharger celui-ci.

## Ce qu'il ne doit pas devenir

- un shell universel pour tout le repo (pour ça, le shell par défaut `nix develop` suffit) ;
- un conteneur de tooling ops (Colmena, OpenTofu, etc., qui sont déjà exposés en `nix run .#...` et n'ont pas besoin d'un shell) ;
- un shell avec des dépendances lourdes non justifiées par le développement .NET.

Voir aussi `docs/devshells.md` pour la liste complète des shells exposés.

# DevShells

## Philosophie

Les devShells de `workstation` sont locaux et orientes poste de travail personnel.

Regle de separation :
- `foundation` — shells generiques et partages (outillage serveur, CI, scripts infra)
- `workstation` — shells de productivite developpeur, specifiques au poste utilisateur

Un shell doit contenir des outils CLI et des runtimes.
Les editeurs et IDE sont des applications desktop — ils ne vivent pas dans un shell.

## Separation editors / shell

| Couche | Ce qu'elle contient | Localisation |
|---|---|---|
| devShell `.NET` | SDK, Docker CLI, outils CLI | `devshells/dotnet.nix` |
| Applications dev | VS Code, Rider, WebStorm | `modules/apps/editors.nix` |

Les editeurs sont des applications desktop. Ils sont installes via le profil `dev`
et disponibles a tout moment sur le poste. Le shell fournit l'environnement dans
lequel ces editeurs travaillent (SDK, runtimes, outils CLI).

## Shell .NET — `devShells.dotnet`

Commande :

```bash
nix develop .#dotnet
```

Definition : `devshells/dotnet.nix`.

Ce shell est **local a `workstation`**. Il n'est pas consomme depuis `foundation` et ne doit pas y migrer.

### Contenu

| Outil | Role |
|---|---|
| `dotnet-sdk` | SDK .NET — compilation, tests, publish |
| `git` | Version control |
| `curl` | HTTP client |
| `jq` | JSON processing |
| `openssl` | TLS / PKI |
| `pkg-config` | Resolution de dependances natives |
| `docker-client` | Docker CLI (daemon gere par le systeme hote) |
| `playwright` | Automatisation navigateur / tests E2E |

## Pourquoi les IDEs ne sont plus dans le shell

VS Code, Rider et WebStorm sont des applications graphiques desktop.
Les mettre dans un devShell signifiait les telecharger a chaque `nix develop`,
les rendre indisponibles hors du shell, et melanger deux niveaux differents.

Ils vivent desormais dans `modules/apps/editors.nix` et sont installes en tant
que paquets systeme via `profiles/dev.nix`. Ils sont toujours disponibles,
independamment de l'entree dans un shell de dev.

## Pourquoi ce shell est local a `workstation`

Ce shell contient des outils de productivite personnelle (Docker, browser testing)
qui n'ont aucune valeur dans un contexte serveur ou CI generique.
Ils appartiennent au poste de travail, pas au socle partage.

`foundation` ne doit pas connaitre les besoins d'un poste de dev personnel.

## Etendre le shell

Ajouter des outils dans `devshells/dotnet.nix`, section `packages`.

Exemples d'extensions :

```nix
nodejs
caddy
mkcert
httpie
```

## Ajouter un nouvel editeur / IDE

Ajouter le package dans `modules/apps/editors.nix`, section `environment.systemPackages`.

Exemple :

```nix
jetbrains.goland
```

## Ajouter un nouveau devShell

1. Creer `devshells/<nom>.nix`
2. L'exposer dans `flake.nix` via `devShells.<system>.<nom>`
3. Documenter son usage dans ce fichier

## Quand passer un shell dans `foundation`

Uniquement si le shell est :
- generique (pas de tooling utilisateur ou IDE)
- utile sur des machines serveur ou CI
- stable et clairement delimite

Un shell de productivite personnelle reste dans `workstation`.

# DevShells

## Philosophie

Les devShells de `infra` sont locaux et orientes poste de travail personnel.

Regle de placement :
- `infra/modules/devshells/` — shells de productivite developpeur, specifiques au poste utilisateur
- les shells generiques de tooling serveur ou CI ne sont pas portes par ce repo aujourd'hui ; les ajouter ici uniquement quand un besoin reel emerge

Un shell doit contenir des outils CLI et des runtimes.
Les editeurs et IDE sont des applications desktop — ils ne vivent pas dans un shell.

## Separation editors / shell

| Couche | Ce qu'elle contient | Localisation |
|---|---|---|
| devShell `.NET` | SDK, Docker CLI, outils CLI | `modules/devshells/dotnet.nix` |
| Applications dev | VS Code, Rider, WebStorm, Neovim, GitKraken | `modules/apps/editors.nix` + `modules/apps/dev.nix` |
| Containers locaux de dev | Podman + compatibilite Docker locale | `modules/containers/podman.nix` via `modules/profiles/dev.nix` |

Les editeurs sont des applications desktop. Ils sont installes via le profil `dev`
et disponibles a tout moment sur le poste. Le shell fournit l'environnement dans
lequel ces editeurs travaillent (SDK, runtimes, outils CLI).

## Shell .NET — `devShells.dotnet`

Commande :

```bash
nix develop .#dotnet
```

Definition : `modules/devshells/dotnet.nix`.

Ce shell est **local au monorepo `infra`**, dans `infra/modules/devshells/dotnet.nix`. Il sert le poste de travail personnel et n'est pas exporte vers un autre repo.

### Contenu

| Outil | Role |
|---|---|
| `dotnet-sdk` | SDK .NET — compilation, tests, publish |
| `git` | Version control |
| `curl` | HTTP client |
| `jq` | JSON processing |
| `openssl` | TLS / PKI |
| `pkg-config` | Resolution de dependances natives |
| `docker-client` | Docker CLI (ici oriente vers Podman quand le profil `dev` est actif) |
| `playwright` | Automatisation navigateur / tests E2E |

## Pourquoi les IDEs ne sont plus dans le shell

VS Code, Rider et WebStorm sont des applications graphiques desktop.
Les mettre dans un devShell signifiait les telecharger a chaque `nix develop`,
les rendre indisponibles hors du shell, et melanger deux niveaux differents.

Ils vivent desormais dans `modules/apps/editors.nix` et `modules/apps/dev.nix`
et sont installes en tant que paquets systeme via `modules/profiles/dev.nix`.
Ils sont toujours disponibles, independamment de l'entree dans un shell de dev.

## Pourquoi ce shell est local au repo

Ce shell contient des outils de productivite personnelle (Docker, browser testing)
qui n'ont aucune valeur dans un contexte serveur ou CI generique.
Ils appartiennent au poste de travail, et restent versionnes ici tant qu'aucun
autre repo n'a besoin de les consommer.

## Relation shell `.NET` / Podman

Le shell `.NET` garde le binaire `docker-client`, mais le backend containers local
est desormais structure cote systeme dans `modules/containers/podman.nix`.

But :

- garder le shell centre sur les outils CLI
- garder le moteur de containers au niveau systeme
- fournir une compatibilite Docker utile pour les workflows dev locaux

## Etendre le shell

Ajouter des outils dans `modules/devshells/dotnet.nix`, section `packages`.

Exemples d'extensions :

```nix
nodejs
caddy
mkcert
httpie
```

## Ajouter un nouvel editeur / IDE

Ajouter :

- un editeur / IDE dans `modules/apps/editors.nix`
- une application dev desktop non-editeur dans `modules/apps/dev.nix`

Exemple :

```nix
jetbrains.goland
```

## Ajouter un nouveau devShell

1. Creer `modules/devshells/<nom>.nix`
2. L'exposer dans `flake.nix` via `devShells.<system>.<nom>`
3. Documenter son usage dans ce fichier

## Quand extraire un shell hors de ce repo

Aujourd'hui, aucun shell n'est extrait : le repo ne consomme plus d'input externe pour ses devShells.

Un shell pourrait justifier d'etre extrait vers un autre repo seulement s'il est :
- generique (pas de tooling utilisateur ou IDE)
- utile sur des machines serveur ou CI
- stable et clairement delimite
- reellement consomme par au moins un second repo

Un shell de productivite personnelle reste dans `infra/modules/devshells/`.

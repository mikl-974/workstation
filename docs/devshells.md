# DevShells

## Philosophie

Les devShells de `workstation` sont locaux et orientes poste de travail personnel.

Regle de separation :
- `foundation` — shells generiques et partages (outillage serveur, CI, scripts infra)
- `workstation` — shells de productivite developpeur, specifiques au poste utilisateur

Un shell qui depend d'un IDE, de Docker Desktop, ou de tooling personnel n'a pas sa place dans `foundation`.

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
| `vscode` | Editeur de code |

### Rider et WebStorm

Rider et WebStorm sont prepares dans `devshells/dotnet.nix` sous forme de lignes commentees :

```nix
# jetbrains.rider
# jetbrains.webstorm
```

Pour les activer, decommenter dans `devshells/dotnet.nix`. Les deux packages sont disponibles dans nixpkgs.

## Pourquoi ce shell est local a `workstation`

Ce shell contient des outils de productivite personnelle (IDE, Docker, browser testing) qui n'ont aucune valeur dans un contexte serveur ou CI generique. Ils appartiennent au poste de travail, pas au socle partage.

`foundation` ne doit pas connaitre les besoins d'un poste de dev personnel.

## Etendre le shell

Ajouter des outils dans `devshells/dotnet.nix`, section `packages`.

Exemples d'extensions :

```nix
nodejs
nodePackages.npm
caddy
mkcert
httpie
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

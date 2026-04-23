# Workflow de mise a jour locale

## Objectif

Ce document decrit le workflow simple et explicite pour mettre a jour la configuration `workstation` directement depuis la machine :

- synchroniser le repo avec Git
- modifier la configuration
- verifier l'etat Git
- appliquer la configuration avec `nixos-rebuild`
- valider le resultat

Il couvre le cas normal d'une machine deja installee.

## Principe

Sur une machine `workstation`, la source de verite reste le repo Git local.

Le cycle normal est :

1. se placer dans le clone local
2. recuperer l'etat distant
3. faire les modifications
4. verifier les changements avec Git
5. appliquer avec `sudo nixos-rebuild switch --flake .#<host>`
6. tester
7. commit/push si les changements doivent etre conserves

Home Manager est integre au systeme :

- `nixos-rebuild switch` applique a la fois la configuration systeme
- et la partie la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`) pour l'utilisateur defini dans `vars.nix`

## Prerequis

- la machine dispose deja d'un clone local du repo
- Git est configure sur la machine
- la machine connait son host (`main`, `laptop`, `gaming`, ...)
- l'utilisateur courant a les droits `sudo`

Exemple :

```bash
cd ~/workstation
hostname
git remote -v
```

## Workflow standard

### 1. Se placer dans le repo

```bash
cd ~/workstation
```

### 2. Verifier l'etat Git avant toute modification

```bash
git status --short
git branch --show-current
```

Si le repo local contient deja des changements non commites, les traiter avant de continuer.

### 3. Recuperer les changements distants

```bash
git pull --ff-only
```

Pourquoi `--ff-only` :

- evite les merges implicites
- garde un historique propre
- force a resoudre explicitement tout ecart local

### 4. Modifier la configuration

Exemples typiques :

- ajouter/modifier un paquet dans `modules/apps/`
- ajuster un module dans `modules/desktop/`
- changer un profil dans `modules/profiles/`
- ajouter un dotfile dans `dotfiles/` + la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`)
- mettre a jour la documentation dans `docs/`

### 5. Relire les changements Git

```bash
git status --short
git diff --stat
git diff
```

Objectif :

- verifier qu'il n'y a que les fichiers attendus
- verifier que la modification est au bon endroit architectural
- detecter toute derive ou tout melange de responsabilites

### 6. Appliquer la configuration

Depuis le repo local :

```bash
sudo nixos-rebuild switch --flake .#$(hostname)
```

Ou explicitement :

```bash
sudo nixos-rebuild switch --flake .#main
```

Utiliser la forme explicite si :

- le hostname systeme ne correspond pas au nom du host dans `flake.nix`
- on travaille sur une autre cible que la machine courante

## Ce que fait `nixos-rebuild switch`

- reconstruit la configuration NixOS du host
- active la nouvelle generation systeme
- applique Home Manager integre
- met a jour les symlinks de la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`)

Il n'est pas necessaire de lancer un `home-manager switch` separe dans cette architecture.

## 7. Verifier apres rebuild

Verification minimale :

```bash
sudo systemctl status NetworkManager --no-pager
nixos-rebuild list-generations
git status --short
```

Verification applicative selon le changement :

```bash
which firefox
which zathura
which thunar
ls -la ~/.config
```

Pour un controle post-install plus large :

```bash
nix run .#post-install-check -- --host $(hostname)
```

## 8. Commit des changements

Si la modification doit rester versionnee :

```bash
git add .
git commit -m "feat: describe the change"
```

Utiliser un commit simple et cible.
Ne pas melanger plusieurs sujets dans le meme commit.

## 9. Push

Si la machine a acces au remote et que le changement doit etre publie :

```bash
git push
```

Le push vient **apres** verification locale et rebuild reussi.

## Workflow court pour une mise a jour simple

```bash
cd ~/workstation
git pull --ff-only
$EDITOR modules/apps/daily.nix
git diff
sudo nixos-rebuild switch --flake .#$(hostname)
git add .
git commit -m "feat: update daily apps"
git push
```

## Cas particulier : dotfiles

Pour un changement de dotfile :

1. modifier `dotfiles/<app>/...`
2. verifier que la composition Home Manager active (`home/targets/<host>.nix` ou, en compatibilité, `home/users/default.nix`) reference bien ce fichier
3. appliquer :

```bash
sudo nixos-rebuild switch --flake .#$(hostname)
```

Les liens Home Manager seront reappliques automatiquement.

## Cas particulier : simple synchronisation sans modification locale

Si la machine doit seulement recuperer la derniere config du repo :

```bash
cd ~/workstation
git pull --ff-only
sudo nixos-rebuild switch --flake .#$(hostname)
```

## Ce qu'il faut eviter

- modifier la machine sans passer par le repo Git local
- faire un `git pull` avec des changements locaux non compris
- lancer `home-manager switch` en parallele sans raison
- ajouter des modifications non relues avant rebuild
- utiliser le host GitHub direct si un clone local propre est deja disponible

## Resume operatoire

```bash
cd ~/workstation
git status --short
git pull --ff-only
# modifier les fichiers
git diff
sudo nixos-rebuild switch --flake .#$(hostname)
nix run .#post-install-check -- --host $(hostname)
git add .
git commit -m "feat: update workstation config"
git push
```

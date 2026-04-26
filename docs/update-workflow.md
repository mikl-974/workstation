# Workflow de mise a jour

## `ms-s1-max`

Depuis la machine elle-meme :

```bash
sudo nixos-rebuild switch --flake .#ms-s1-max
```

Puis :

```bash
nix run .#post-install-check -- --host ms-s1-max
```

## `contabo`

Depuis une machine operateur avec acces SSH :

```bash
nix run .#deploy-contabo
```

## `mac-mini`

Depuis le Mac :

```bash
darwin-rebuild switch --flake .#mac-mini
```

## Changer les capacites logicielles de `ms-s1-max`

Modifier :

- `targets/hosts/ms-s1-max/config/capabilities.nix`

Ne pas chercher dans un profil abstrait.
La cartographie est volontairement locale a la cible.

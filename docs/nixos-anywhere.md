# NixOS Anywhere

## Host concerne

Aujourd'hui, le parcours NixOS Anywhere branche dans ce repo concerne
principalement :

- `contabo`

`ms-s1-max` ne porte pas encore de `disko.nix`.

## Commande

```bash
nix run .#install-anywhere -- contabo <IP-CIBLE>
```

## Ce que le script fait

1. lance `doctor`
2. lance `validate-install`
3. verifie la cle SSH de la cible
4. lance `nixos-anywhere`

## Condition minimale

Le host doit avoir :

- un `disko.nix`
- un `disk` reel renseigne dans `vars.nix`

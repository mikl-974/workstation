# Installation manuelle

Quand NixOS Anywhere n'est pas utilisable (pas de SSH sur la cible, machine
physique sans réseau préinstallé, réinstall en local, etc.), deux flux
manuels existent — l'un et l'autre exécutent **exactement** la même séquence
`disko → nixos-install --flake`.

| Contexte | App Nix | Script | Garde-fou disque |
|---|---|---|---|
| Live ISO NixOS bootée sur la machine cible | `nix run .#install-from-live -- <host>` | `scripts/install-from-live.sh` | aucun (le live ISO ne touche pas au disque) |
| NixOS déjà installé, on installe sur **un autre disque** | `sudo nix run .#install-from-existing -- <host>` | `scripts/install-from-existing.sh` | refuse si le disque cible porte `/` |
| Auto-détection (live vs existing) | `nix run .#install-manual -- <host>` | `scripts/install-manual.sh` | délègue au bon script |

Toutes les apps lisent `targets/hosts/<host>/{vars,disko}.nix` et exigent que
`validate-install` passe avant toute action destructive.

---

## Flux nominal — depuis un live ISO NixOS

3 commandes, dans cet ordre :

```bash
nix-shell -p git nix
git clone https://github.com/mikl-974/infra /tmp/infra && cd /tmp/infra
sudo nix --extra-experimental-features 'nix-command flakes' \
  run .#install-from-live -- <host>
```

Le script enchaîne :

1. `validate-install` (échec → arrêt avant action destructive)
2. confirmation interactive (disque cible affiché)
3. `disko --mode disko targets/hosts/<host>/disko.nix` (formate + monte sous `/mnt`)
4. copie du repo dans `/mnt/etc/infra` (utile au premier boot)
5. `nixos-install --no-root-passwd --flake .#<host> --root /mnt`
   — les mots de passe utilisateurs viennent de sops, pas besoin de prompt
6. confirmation reboot

## Flux nominal — depuis un NixOS déjà installé

```bash
sudo nix run .#install-from-existing -- <host>
```

Différence avec live : refuse explicitement si `vars.nix:disk` correspond au
disque qui porte `/` sur la machine courante. Conçu pour réinstaller un
disque secondaire ou monté en passthrough sans clé USB.

---

## Pré-requis (les deux flux)

- `targets/hosts/<host>/vars.nix` complet (champ `disk` correctement renseigné — vérifier `lsblk`)
- `targets/hosts/<host>/disko.nix` présent
- `targets/hosts/<host>/default.nix` exposé via `nixosConfigurations` dans `flake.nix`
- `nix run .#validate-install -- <host>` passe sans erreur

---

## En cas d'échec

| Symptôme | Diagnostic |
|---|---|
| `validate-install a échoué` | placeholders restants ou fichiers absents — relancer `nix run .#doctor -- --host <host>` |
| disko refuse de formater | partition montée — `umount -R /mnt` puis recommencer |
| `nixos-install` casse en plein milieu | relancer le script : disko est idempotent, `nixos-install` reprend là où il en était |
| Pas de réseau sur le live ISO | `wpa_supplicant -B -i wlan0 -c <(wpa_passphrase SSID PASS) && dhclient wlan0` |
| Détection auto se trompe | forcer avec `--method live` ou `--method existing` |

---

## Référence détaillée (partitionnement manuel sans disko, etc.)

Voir [`docs/manual-install-reference.md`](manual-install-reference.md).
Cette référence couvre le partitionnement à la main, les options btrfs, les
cas où `disko.nix` n'est pas dispo, et le débogage profond.

# Installation manuelle

Quand NixOS Anywhere n'est pas utilisable (pas de SSH, pas de kexec, hyperviseur
non compatible, etc.), trois flux existent. **Choisir le bon flux dépend
uniquement de l'état du disque cible**, pas de la procédure mentale d'install.

## Quel flux pour quel cas ?

| Cas | État du disque cible | Tu veux | Commande |
|---|---|---|---|
| **A. Reconfigurer** | NixOS déjà installé et bootable, tu gardes le layout | appliquer ta config par-dessus, sans toucher au disque | `sudo nix run .#reconfigure -- <host>` |
| **B. Installer sur un autre disque** | Disque cible ≠ disque qui porte `/` sur le système courant | partitionner et installer un nouveau système sur ce disque | `sudo nix run .#install-from-existing -- <host>` |
| **C. Réinstaller sur le disque qui porte `/`** | Le disque cible est en cours d'utilisation | wipe complet + réinstall | impossible en place — booter sur un live ISO et lancer `install-from-live`, ou utiliser NixOS Anywhere via kexec |

Cas typiques :

- **OrbStack, hyperviseur (UTM, VMware, Proxmox), VPS qui livre déjà un NixOS** → cas A : `reconfigure`.
- **Réinstall propre d'un disque secondaire ou en passthrough** → cas B : `install-from-existing`.
- **Wipe + install neuve sur la machine courante** → cas C : live ISO USB ou `install-anywhere localhost` via kexec.

Tous les flux exécutent `validate-install` avant toute action, et tous les flux
destructifs (B et C) appliquent **exactement** la même séquence
`disko → nixos-install --flake`. Le résultat système est identique entre
A, B et C dès qu'on parle uniquement de la configuration logicielle.

---

## A. Reconfigurer (le plus fréquent)

```bash
# 1. Récupérer le repo (premier setup uniquement)
nix-shell -p git
git clone https://github.com/mikl-974/infra /etc/infra
cd /etc/infra

# 2. Appliquer la config
sudo nix run .#reconfigure -- <host>
# équivaut à :
#   nix run .#validate-install -- <host>
#   sudo nixos-rebuild switch --flake .#<host>
```

Modes alternatifs : `--mode test` (apply sans changer le boot par défaut),
`--mode boot` (stage pour le prochain reboot), `--mode dry-activate` (no-op
descriptif).

**Identique à une install neuve ?** Côté config Nix : oui, à 100%.
Différences inévitables :

- layout disque : celui de l'installeur d'origine, pas celui de `disko.nix`
- `system.stateVersion` : celle d'origine si différente — laisse-la, ne la force pas
- état héritée (`/var`, `/home`, …) : préservée

Pour un usage VM dev (OrbStack), ces différences n'ont aucun impact pratique.

## B. Installer sur un autre disque depuis un NixOS existant

```bash
sudo nix run .#install-from-existing -- <host>
```

Garde-fou : refuse si `vars.nix:disk` correspond au disque qui porte `/`.

## C. Réinstaller le disque courant

Pas possible en place. Trois options :

```bash
# C.1 — Live ISO NixOS, depuis la machine cible bootée sur USB
sudo nix run .#install-from-live -- <host>

# C.2 — NixOS Anywhere en localhost via kexec (le plus simple si pas de USB)
nix run .#install-anywhere -- <host> 127.0.0.1
# (la cible doit avoir un sshd actif accessible en root, et nixos-anywhere
#  installe son installeur via kexec ; au reboot, le système est neuf)

# C.3 — NixOS Anywhere depuis une autre machine
nix run .#install-anywhere -- <host> <ip-cible>
```

---

## Récapitulatif des apps

| App | Action | Destructif |
|---|---|---|
| `nix run .#reconfigure -- <host>` | applique la config sur le système courant | non |
| `sudo nix run .#install-from-live -- <host>` | install neuve depuis live ISO | oui (disque cible) |
| `sudo nix run .#install-from-existing -- <host>` | install neuve depuis NixOS existant, autre disque | oui (disque cible, refuse `/`) |
| `nix run .#install-manual -- <host>` | dispatcher live↔existing | oui |
| `nix run .#install-anywhere -- <host> <ip>` | install à distance via SSH+kexec | oui |

---

## Pré-requis communs

- `targets/hosts/<host>/vars.nix` complet (et pour B/C : `disk` correct, vérifier `lsblk`)
- `targets/hosts/<host>/default.nix` exposé via `nixosConfigurations` dans `flake.nix`
- pour B/C : `targets/hosts/<host>/disko.nix` présent
- `nix run .#validate-install -- <host>` passe sans erreur

## En cas d'échec

| Symptôme | Diagnostic |
|---|---|
| `validate-install a échoué` | placeholders restants — `nix run .#doctor -- --host <host>` |
| disko refuse de formater | partition montée — `umount -R /mnt` puis recommencer |
| `nixos-install` casse en plein milieu | relancer le script : disko est idempotent |
| `nixos-rebuild` se plaint d'un `fileSystems` manquant | la config référence un point de montage que la VM n'a pas — soit ajuster le host, soit créer le point de montage |
| Pas de réseau sur le live ISO | `wpa_supplicant -B -i wlan0 -c <(wpa_passphrase SSID PASS) && dhclient wlan0` |
| Détection auto du dispatcher se trompe | forcer avec `--method live` ou `--method existing` |

---

## Référence détaillée (partitionnement manuel sans disko, etc.)

Voir [`docs/manual-install-reference.md`](manual-install-reference.md).

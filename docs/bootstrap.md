# Bootstrap

## Cloner le repo

```bash
git clone https://github.com/mikl-974/infra
cd infra
```

## Inspecter un host

```bash
nix run .#show-config -- ms-s1-max
nix run .#show-config -- contabo
```

## Validation

```bash
nix run .#doctor -- --host ms-s1-max
nix run .#validate-install -- ms-s1-max
```

## Installation

- `contabo` : NixOS Anywhere possible car `disko.nix` est branche
- `ms-s1-max` : parcours manuel / reconfiguration locale
- `mac-mini` : `darwin-rebuild`

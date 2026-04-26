# IA locale

## Decision retenue

L'IA de `ms-s1-max` est maintenant modelisee comme une capacite locale du host,
pas comme une stack infra.

Le point d'entree unique est :

- `targets/hosts/ms-s1-max/config/capabilities.nix`

## Ce qui est active sur `ms-s1-max`

- `nixpkgs.config.rocmSupport = true`
- `services.ollama.enable = true`
- `services.ollama.package = pkgs.ollama-rocm`
- paquet `ollama-rocm`
- paquet `llama-cpp-rocm`
- paquets systeme `rocm-runtime`, `rocminfo`, `rocm-smi`, `amdsmi`
- paquet `opencode-desktop`
- `services.flatpak.enable = true`
- user `mfo` ajoute au groupe `render`

Si le GPU AMD est mal detecte par ROCm, le host peut aussi fixer :

- `services.ollama.rocmOverrideGfx = "<gfx-version>"`

## Outils dev associes

Le meme fichier declare aussi les outils de dev relies au poste principal :

- `vscode`
- `jetbrains.rider`
- `jetbrains.webstorm`
- `gitkraken`

## AnythingLLM

`AnythingLLM` n'est pas package proprement dans `nixpkgs` aujourd'hui.
Le repo retient donc la position explicite suivante :

- Flatpak est active sur `ms-s1-max`
- l'installation de l'app reste :

```bash
flatpak install flathub com.anythingllm.anythingllm
```

Ce choix est documente et assume.
Il evite de reintroduire un faux module "IA local" abstrait qui cacherait la
realite de ce que la machine installe effectivement.

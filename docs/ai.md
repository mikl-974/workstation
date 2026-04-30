# IA locale

## Decision retenue

L'IA de `ms-s1-max` est maintenant modelisee comme une capacite locale du host,
pas comme une stack infra.

Le point d'entree unique est :

- `targets/hosts/ms-s1-max/config/capabilities.nix`

## Ce qui est active sur `ms-s1-max`

- `nixpkgs.config.rocmSupport = true`
- paquet `llama-cpp-rocm`
- paquet `python3Packages.huggingface-hub` (`hf`)
- repertoires persistants `/var/lib/llama-cpp/models` et `/var/lib/llama-cpp/cache/*`
- paquets systeme `rocm-runtime`, `rocminfo`, `rocm-smi`, `amdsmi`
- paquet `opencode-desktop`
- `services.flatpak.enable = true`
- user `mfo` ajoute au groupe `render`
- user systeme `llama-cpp` pour les services et caches persistants
- override ROCm Strix Halo `HSA_OVERRIDE_GFX_VERSION = "11.5.1"`
- workaround MIOpen `MIOPEN_DEBUG_DISABLE_FIND_DB = "1"`

## Tuning ROCm pour Strix Halo

Sur `ms-s1-max`, le host fixe maintenant explicitement :

- `environment.variables.HSA_OVERRIDE_GFX_VERSION = "11.5.1"`
- `environment.variables.MIOPEN_DEBUG_DISABLE_FIND_DB = "1"`

Pourquoi :

- `HSA_OVERRIDE_GFX_VERSION = "11.5.1"` force les consumers ROCm a traiter le
  GPU Strix Halo comme `gfx1151`, ce qui evite les problemes de detection sur
  des builds encore en retard sur cette generation.
- `MIOPEN_DEBUG_DISABLE_FIND_DB = "1"` evite l'usage de la Find DB MIOpen, qui
  peut etre incomplete ou mal calibree sur du materiel recent, et reduit les
  faux demarrages rates sur certaines libs ROCm.

Le repo applique le tuning a deux niveaux :

- globalement via `environment.variables` pour les usages manuels (`llama.cpp`,
  outils ROCm, shells)

Pour le moment, Ollama est retire de la configuration active : le tuning ROCm
reste donc porte au niveau host pour `llama.cpp` direct et les outils ROCm.

## Outils dev associes

Le meme fichier declare aussi les outils de dev relies au poste principal :

- `vscode`
- `jetbrains.rider`
- `jetbrains.webstorm`
- `gitkraken`

## Ajouter un modele llama.cpp manuellement

Le repo installe la CLI Hugging Face `hf` mais ne place pas les poids de modeles
dans le `/nix/store`.

Pour `llama.cpp`, utiliser des fichiers `GGUF` et les stocker sous :

```bash
/var/lib/llama-cpp/models
```

Authentification Hugging Face si le modele est restreint :

```bash
hf auth login
```

Telechargement d'un modele GGUF :

```bash
mkdir -p /var/lib/llama-cpp/models/<modele>
hf download <repo-hf> <fichier.gguf> \
  --local-dir /var/lib/llama-cpp/models/<modele>
```

Exemple de lancement manuel :

```bash
llama-server -m /var/lib/llama-cpp/models/<modele>/<fichier.gguf>
```

Le repertoire est cree declarativement par NixOS et reste hors du store pour
permettre des tests de quantizations ou de variantes sans rebuild systeme.

## Services `llama.cpp`

Le repo ne garde plus un service systemd `llama-cpp-server` code en dur.
`systems/apps/llama-cpp.nix` expose maintenant un module declaratif
`infra.ai.inference.llamaCpp` qui :

- genere un service systemd par modele
- separe les defaults moteur des declarations de modeles du host
- garde `llama.cpp` distinct de `ollama`, qui n'est pas active actuellement
- laisse les futurs routeurs/UI hors du moteur d'inference

Sur `ms-s1-max`, `targets/hosts/ms-s1-max/config/capabilities.nix` declare :

- `llama-cpp-qwen36-27b-bf16.service`
- `llama-cpp-gemma4.service`

Le host fixe des defaults `llama.cpp` adaptes a Strix Halo :

- `package = pkgs.llama-cpp-rocm`
- `host = "127.0.0.1"`
- `-fit off`
- `--metrics`
- `GGML_CUDA_ENABLE_UNIFIED_MEMORY = "1"`
- pas d'ouverture firewall par defaut

Modeles servis :

- `qwen36-27b-bf16`
  - source Hugging Face : `unsloth/Qwen3.6-27B-GGUF:BF16`
  - bind `127.0.0.1:8080`
  - autostart active
  - aligne sur la commande validee :
    `llama-server -hf unsloth/Qwen3.6-27B-GGUF:BF16 --ctx-size 4096 -fit off --host 127.0.0.1 --port 8080`
- `gemma4`
  - source Hugging Face : `ggml-org/gemma-4-E2B-it-GGUF`
  - bind `127.0.0.1:8081`
  - autostart desactive, donc non accessible apres reboot tant qu'il n'est pas lance manuellement

Le module cree aussi les repertoires persistants :

- `/var/lib/llama-cpp/cache`
- `/var/lib/llama-cpp/cache/huggingface`
- `/var/lib/llama-cpp/cache/llama`
- `/var/lib/llama-cpp/models`

et utilise un user systeme dedie pour rendre les caches HF persistants et
fiables entre redemarrages.

Les services Hugging Face attendent aussi `network-online.target` et continuent
de retenter le demarrage apres boot au lieu de rester bloques en echec si le
reseau n'etait pas encore pret au premier lancement.

Commandes utiles :

```bash
systemctl list-unit-files 'llama-cpp-*'
systemctl status llama-cpp-qwen36-27b-bf16
journalctl -u llama-cpp-qwen36-27b-bf16 -f
curl http://127.0.0.1:8080/health
sudo systemctl start llama-cpp-gemma4
systemctl status llama-cpp-gemma4
curl http://127.0.0.1:8081/health
```

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

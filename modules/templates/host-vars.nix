# Template de configuration machine — targets/hosts/<name>/vars.nix
#
# Ce fichier est le seul à éditer pour configurer une nouvelle machine.
# Copier ce template dans targets/hosts/<name>/vars.nix et remplir les valeurs.
#
# Usage :
#   cp modules/templates/host-vars.nix targets/hosts/<name>/vars.nix
#   # éditer targets/hosts/<name>/vars.nix
#   nix run .#validate-install -- <name>
#
# Ou utiliser le script d'initialisation :
#   nix run .#init-host -- <name>
{
  # Contexte machine.
  # Bare metal vs VM n'est pas déclaré ici : ce repo l'exprime via l'import
  # éventuel de modules/profiles/virtual-machine.nix dans le host concret.

  # Plateforme NixOS.
  # Valeurs supportees : "x86_64-linux", "aarch64-linux"
  system = "x86_64-linux";

  # Nom d'utilisateur système.
  # Doit être un identifiant Unix valide (lettres minuscules, chiffres, tirets).
  # Exemple : "alice", "bob", "mikl"
  username = "DEFINE_USERNAME";

  # Hostname de la machine.
  # Doit correspondre à la clé nixosConfigurations dans flake.nix.
  # Valeurs disponibles : "main", "laptop", "gaming"
  hostname = "DEFINE_HOSTNAME";

  # Disque cible pour l'installation (requis si le host utilise disko).
  # Lancer `lsblk` sur la machine cible pour identifier le bon disque.
  # Exemples : "/dev/nvme0n1", "/dev/sda", "/dev/vda"
  disk = "/dev/DEFINE_DISK";

  # Fuseau horaire.
  # Liste complète : timedatectl list-timezones
  # Exemples : "Europe/Paris", "America/New_York", "UTC"
  timezone = "Europe/Paris";

  # Locale système.
  # Exemples : "fr_FR.UTF-8", "en_US.UTF-8"
  locale = "fr_FR.UTF-8";
}

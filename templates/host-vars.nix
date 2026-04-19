# Template de configuration machine — hosts/<name>/vars.nix
#
# Ce fichier est le seul à éditer pour configurer une nouvelle machine.
# Copier ce template dans hosts/<name>/vars.nix et remplir les valeurs.
#
# Usage :
#   cp templates/host-vars.nix hosts/<name>/vars.nix
#   # éditer hosts/<name>/vars.nix
#   nix run .#validate-install -- <name>
#
# Ou utiliser le script d'initialisation :
#   nix run .#init-host -- <name>
{
  # Architecture de la machine cible.
  # "x86_64-linux" pour Intel/AMD, "aarch64-linux" pour ARM / VMs Apple Silicon
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

  # Mot de passe initial (en clair — à changer après la première connexion via `passwd`).
  # Ce mot de passe est utilisé pour l'utilisateur principal et root.
  # ATTENTION : stocker un mot de passe en clair dans le dépôt n'est pas recommandé
  # en production — utilisez hashedPasswordFile ou agenix/sops-nix pour les secrets.
  initialPassword = "DEFINE_PASSWORD";
}

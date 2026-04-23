# Machine-specific variables for host 'contabo'.
#
# `contabo` is the Contabo VPS that hosts Dokploy-operated stacks
# (homepage, beszel hub, tsdproxy, kopia, nextcloud-qtalk).
# It is the first server-class target in this repo.
{
  system   = "x86_64-linux";
  username = "admin";              # operator account exposed by infra.users.admin
  hostname = "contabo";            # matches nixosConfigurations key in flake.nix
  disk     = "/dev/vda";           # Contabo VPS standard root disk; override here if cloned to a host that uses a different device
  timezone = "Europe/Paris";
  locale   = "en_US.UTF-8";
}

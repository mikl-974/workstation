#!/usr/bin/env bash
set -euo pipefail

# `tofu apply` for the `cloudflare-ext` cloud target workspace
# (deployments/topology.nix → kind = "cloudflareContainers").
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root/tofu/stacks/cloudflare-ext"
tofu init -input=false -upgrade
exec tofu apply

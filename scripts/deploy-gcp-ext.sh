#!/usr/bin/env bash
set -euo pipefail

# `tofu apply` for the `gcp-ext` cloud target workspace
# (deployments/topology.nix → kind = "gcpCloudRun").
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root/tofu/stacks/gcp-ext"
tofu init -input=false -upgrade
exec tofu apply

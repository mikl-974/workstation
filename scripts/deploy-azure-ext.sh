#!/usr/bin/env bash
set -euo pipefail

# `tofu apply` for the `azure-ext` cloud target workspace
# (deployments/topology.nix → kind = "azureContainerApps").
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root/tofu/stacks/azure-ext"
tofu init -input=false -upgrade
exec tofu apply

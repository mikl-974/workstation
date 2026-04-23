#!/usr/bin/env bash
set -euo pipefail

# Apply the `contabo` NixOS host configuration via Colmena.
exec colmena apply --on contabo --config ./deployments/colmena.nix

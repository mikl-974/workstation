#!/usr/bin/env bash
set -euo pipefail

# Apply every NixOS host configuration declared in deployments/colmena.nix.
# Hosts not present in the Colmena hive (e.g. workstations) are not touched.
exec colmena apply --config ./deployments/colmena.nix

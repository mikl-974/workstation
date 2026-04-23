#!/usr/bin/env bash
set -euo pipefail

# Strict validation of the deployments inventory against the topology and
# stack contracts. Exits non-zero (with the validation error list) if any
# rule from `deployments/validation.nix` is violated.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Print human-readable summary on success; throw on failure.
nix-instantiate --eval --strict --json \
  -E 'let r = import ./deployments/validation.nix; in r.summaryText' \
  | sed -e 's/^"//' -e 's/"$//' -e 's/\\n/\n/g'

# Also force evaluation of the structured outputs so any silent regression on
# the topology/inventory/stacks tree is caught here too.
nix-instantiate --eval --strict --json \
  -E 'let r = import ./deployments/validation.nix; in { inherit (r) summary; }' \
  >/dev/null

# tofu/stacks/gcp-ext/

OpenTofu workspace for the `gcp-ext` cloud target.

- **Kind** : `gcpCloudRun`
- **Region** : `europe-west1` (overridable via `var.region`)

## Responsibility

This workspace owns GCP-side resources required to host stack instances
assigned to `gcp-ext` in `deployments/inventory.nix`.

No stack from this repo is currently assigned to `gcp-ext`. The workspace
exists so the convention is uniform across the three cloud targets.

## Credentials

Use one of:

- `gcloud auth application-default login` (interactive operator)
- `GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json` (CI)

The GCP project id is read from `var.project` (`TF_VAR_project`).

## State

Local state by default. Switch to a remote backend (e.g. GCS) once real
resources are declared. Do NOT commit `*.tfstate`.

## Operating

- `nix run .#plan-gcp-ext`
- `nix run .#deploy-gcp-ext`

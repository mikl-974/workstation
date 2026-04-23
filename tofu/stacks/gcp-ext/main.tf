# Workspace skeleton for the `gcp-ext` cloud target
# (kind = "gcpCloudRun" in deployments/topology.nix).
#
# The provider is declared but credentials are NOT committed: authenticate
# with `gcloud auth application-default login` or set
# `GOOGLE_APPLICATION_CREDENTIALS` to a service-account key file before
# `tofu plan` / `tofu apply`.
#
# Resource declarations are intentionally absent: they will be added when the
# first stack assignment to `gcp-ext` lands in `deployments/inventory.nix`.
provider "google" {
  project = var.project
  region  = var.region
}

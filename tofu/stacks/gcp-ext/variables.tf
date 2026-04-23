variable "project" {
  type        = string
  description = "GCP project hosting the Cloud Run workloads. Set via TF_VAR_project or terraform.tfvars (kept out of git)."
  default     = ""
}

variable "region" {
  type        = string
  description = "GCP region for Cloud Run services."
  default     = "europe-west1"
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to every resource."
  default = {
    repo   = "infra"
    target = "gcp-ext"
  }
}

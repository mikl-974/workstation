variable "account_id" {
  type        = string
  description = "Cloudflare account id that owns the Containers workloads. Set via TF_VAR_account_id or terraform.tfvars (kept out of git)."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Logical tags echoed into resource names where supported."
  default = {
    repo   = "infra"
    target = "cloudflare-ext"
  }
}

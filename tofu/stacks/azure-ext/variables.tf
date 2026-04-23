variable "location" {
  type        = string
  description = "Azure region for the resource group hosting Container Apps workloads."
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group that owns the Container Apps environment."
  default     = "infra-azure-ext"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource in the workspace."
  default = {
    repo   = "infra"
    target = "azure-ext"
  }
}

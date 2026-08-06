variable "tenant_id" {
  type        = string
  description = "Entra ID tenant ID of the demo tenant. Real value lives in terraform.tfvars (git-ignored)."
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID for Azure resources (Key Vault, App Insights). Empty string if the demo tenant has no linked subscription yet."
  default     = ""
}

variable "github_owner" {
  type        = string
  description = "GitHub owner (user or organisation) for the repo."
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name (without owner)."
}

variable "environments" {
  type = map(object({
    id                = string
    display_name      = string
    domain            = string
    location          = string
    env_type          = string
    currency          = string
    language          = string
    cadence           = optional(string, "Moderate")
    security_group_id = optional(string, "")
  }))
  description = <<-EOT
    Map of Power Platform environment slots. Keys are the slot names (e.g. "dev", "test").
    The id is the existing environment GUID in the tenant (used for `terraform import`).
    On a fresh tenant, set id = "" and terraform apply will create new environments.
  EOT
}

variable "tenant_settings" {
  type = object({
    disable_share_with_everyone         = bool
    disable_connection_sharing_everyone = bool
    enable_canvas_app_insights          = bool
    disable_copilot                     = bool
    enable_openai_bot_publishing        = bool
    storage_capacity_warning_threshold  = number
    disable_new_env_creation_non_admins = bool
  })
  description = "Tenant-wide Power Platform settings the showcase depends on."
}


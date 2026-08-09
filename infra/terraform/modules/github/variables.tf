variable "repository" {
  type        = string
  description = "GitHub repository name (without owner)."
}

variable "environments" {
  type = map(object({
    ci_client_id            = string
    ci_tenant_id            = string
    powerplatform_env_id    = string
    powerplatform_env_url   = string
    allowed_branch_patterns = optional(set(string), ["main"])
    prevent_self_review     = optional(bool, true)
    can_admins_bypass       = optional(bool, false)
  }))
  description = "GitHub Environment slots to create with matching CI variables."
}

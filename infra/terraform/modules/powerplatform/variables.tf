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
  description = "Slot map of Power Platform environments."
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
  description = "Tenant-wide Power Platform settings."
}


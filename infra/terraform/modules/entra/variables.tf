variable "github_owner" {
  type        = string
  description = "GitHub owner (user or organisation)."
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name (without owner)."
}

variable "app_registrations" {
  type = map(object({
    display_name       = string
    github_environment = string
    description        = optional(string, "")
  }))
  description = <<-EOT
    App registrations to create. Keys are slot names (e.g. "dev", "test").
    Each app gets an OIDC federated credential scoped to the matching GitHub Environment.
  EOT
}

variable "github_owner" {
  type        = string
  description = "GitHub owner (user or organisation)."
}

variable "github_owner_id" {
  type        = string
  description = "Numeric GitHub owner (user/org) ID, embedded in the federated identity subject to bind the credential to this specific owner regardless of renames."
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name (without owner)."
}

variable "github_repository_id" {
  type        = string
  description = "Numeric GitHub repository ID, embedded in the federated identity subject to bind the credential to this specific repository regardless of renames."
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

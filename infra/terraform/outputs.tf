output "environment_urls" {
  description = "Instance URLs of each Power Platform environment, keyed by slot name."
  value       = module.powerplatform.environment_urls
}

output "environment_ids" {
  description = "GUIDs of each Power Platform environment, keyed by slot name."
  value       = module.powerplatform.environment_ids
}

output "ci_client_ids" {
  description = "Entra client IDs of the CI apps, keyed by slot."
  value       = module.entra.client_ids
}

output "github_environments" {
  description = "GitHub Environments provisioned."
  value       = module.github.environments
}

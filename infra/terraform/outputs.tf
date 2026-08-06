output "environment_urls" {
  description = "Instance URLs of each Power Platform environment, keyed by slot name."
  value       = module.powerplatform.environment_urls
}

output "environment_ids" {
  description = "GUIDs of each Power Platform environment, keyed by slot name."
  value       = module.powerplatform.environment_ids
}

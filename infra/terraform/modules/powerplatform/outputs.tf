output "environment_ids" {
  description = "GUIDs of each Power Platform environment, keyed by slot."
  value       = { for k, e in powerplatform_environment.this : k => e.id }
}

output "environment_urls" {
  description = "Instance URLs of each Power Platform environment, keyed by slot."
  value       = { for k, e in powerplatform_environment.this : k => "https://${e.dataverse.domain}.crm.dynamics.com/" }
}

output "environment_display_names" {
  description = "Display names of each Power Platform environment, keyed by slot."
  value       = { for k, e in powerplatform_environment.this : k => e.display_name }
}

output "required_languages" {
  description = "Required Dataverse LCIDs keyed by environment slot."
  value       = { for slot, env in var.environments : slot => sort(tolist(env.required_languages)) }
}

output "client_ids" {
  description = "Client IDs (application IDs) of each CI app registration, keyed by slot."
  value       = { for k, a in azuread_application.ci : k => a.client_id }
}

output "service_principal_object_ids" {
  description = "Service principal object IDs, keyed by slot."
  value       = { for k, sp in azuread_service_principal.ci : k => sp.object_id }
}

output "application_object_ids" {
  description = "App registration object IDs, keyed by slot."
  value       = { for k, a in azuread_application.ci : k => a.object_id }
}

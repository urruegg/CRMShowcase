output "environments" {
  description = "GitHub Environments created, keyed by slot name."
  value       = [for e in github_repository_environment.envs : e.environment]
}

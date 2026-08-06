locals {
  # GitHub's current default OIDC subject prefix embeds numeric owner + repo IDs
  # so the credential stays bound to this exact owner/repo even across renames:
  #   repo:{owner}@{owner_id}/{repo}@{repo_id}:...
  # See https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers
  gh_sub_prefix = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}"
}

resource "azuread_application" "ci" {
  for_each = var.app_registrations

  display_name     = each.value.display_name
  description      = each.value.description == "" ? "CRM Showcase CI for ${each.value.github_environment}" : each.value.description
  sign_in_audience = "AzureADMyOrg"

  notes = <<-EOT
    Owner: CRM Frontier Firm Showcase (repo: ${var.github_owner}/${var.github_repository}).
    Purpose: CI/CD workload identity for GitHub Actions targeting the ${each.value.github_environment} environment.
    Auth pattern: OIDC federated credentials only. No client secrets. See docs/adr/ADR-0002 and ADR-0004.
  EOT
}

resource "azuread_service_principal" "ci" {
  for_each = var.app_registrations

  client_id                    = azuread_application.ci[each.key].client_id
  app_role_assignment_required = false

  description = "Service principal for GitHub Actions CI in ${each.value.github_environment} environment."

  feature_tags {
    enterprise = true
    gallery    = false
    hide       = false
  }
}

# OIDC federated credential: workflows running in this repo's GitHub Environment
# receive an ID token that this app trusts. No client secret is ever created.
resource "azuread_application_federated_identity_credential" "gh_env" {
  for_each = var.app_registrations

  application_id = azuread_application.ci[each.key].id
  display_name   = "github-${each.value.github_environment}"
  description    = "GitHub Actions OIDC for ${var.github_owner}/${var.github_repository} :: environment ${each.value.github_environment}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "${local.gh_sub_prefix}:environment:${each.value.github_environment}"
}

# Additional federated credential for PR runs so plan-on-PR can still authenticate
# to Entra (but nothing dangerous — the SP has read-only permissions unless a PR
# is merged and the environment approval gate lets an apply-scoped run through).
resource "azuread_application_federated_identity_credential" "gh_pull_request" {
  for_each = var.app_registrations

  application_id = azuread_application.ci[each.key].id
  display_name   = "github-pr-${each.value.github_environment}"
  description    = "GitHub Actions OIDC for pull_request events in ${var.github_owner}/${var.github_repository}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "${local.gh_sub_prefix}:pull_request"
}

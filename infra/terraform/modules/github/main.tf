resource "github_repository_environment" "envs" {
  for_each = var.environments

  environment         = each.key
  repository          = var.repository
  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review
}

# Non-secret variables the CI workflow reads to authenticate + target the right env.
# Client ID and tenant ID are NOT secrets by Microsoft's classification — they are
# identifiers. Real secrecy is provided by the OIDC federation (short-lived tokens
# only for approved runs).
resource "github_actions_environment_variable" "client_id" {
  for_each = var.environments

  repository    = var.repository
  environment   = github_repository_environment.envs[each.key].environment
  variable_name = "AZURE_CLIENT_ID"
  value         = each.value.ci_client_id
}

resource "github_actions_environment_variable" "tenant_id" {
  for_each = var.environments

  repository    = var.repository
  environment   = github_repository_environment.envs[each.key].environment
  variable_name = "AZURE_TENANT_ID"
  value         = each.value.ci_tenant_id
}

resource "github_actions_environment_variable" "pp_env_id" {
  for_each = var.environments

  repository    = var.repository
  environment   = github_repository_environment.envs[each.key].environment
  variable_name = "POWER_PLATFORM_ENV_ID"
  value         = each.value.powerplatform_env_id
}

resource "github_actions_environment_variable" "pp_env_url" {
  for_each = var.environments

  repository    = var.repository
  environment   = github_repository_environment.envs[each.key].environment
  variable_name = "POWER_PLATFORM_ENV_URL"
  value         = each.value.powerplatform_env_url
}

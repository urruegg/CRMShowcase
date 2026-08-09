data "github_repository" "self" {
  name = var.repository
}

locals {
  environment_deployment_policies = tomap({
    for policy in flatten([
      for environment_name, environment in var.environments : [
        for branch_pattern in environment.allowed_branch_patterns : {
          key            = "${environment_name}:${branch_pattern}"
          environment    = environment_name
          branch_pattern = branch_pattern
        }
      ]
    ]) :
    policy.key => {
      environment    = policy.environment
      branch_pattern = policy.branch_pattern
    }
  })
}

resource "github_repository_environment" "envs" {
  for_each = var.environments

  environment         = each.key
  repository          = var.repository
  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "allowed_branches" {
  for_each = local.environment_deployment_policies

  repository     = var.repository
  environment    = github_repository_environment.envs[each.value.environment].environment
  branch_pattern = each.value.branch_pattern
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

resource "github_branch_protection" "main" {
  repository_id = data.github_repository.self.node_id
  pattern       = "main"

  enforce_admins                  = true
  allows_force_pushes             = false
  force_push_bypassers            = []
  allows_deletions                = false
  require_conversation_resolution = true

  required_status_checks {
    strict   = true
    contexts = ["gate1"]
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
    pull_request_bypassers          = []
  }
}

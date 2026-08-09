module "powerplatform" {
  source = "./modules/powerplatform"

  environments    = var.environments
  tenant_settings = var.tenant_settings
}

data "github_repository" "self" {
  full_name = "${var.github_owner}/${var.github_repository}"
}

data "github_user" "owner" {
  username = var.github_owner
}

module "entra" {
  source = "./modules/entra"

  github_owner         = var.github_owner
  github_owner_id      = tostring(data.github_user.owner.id)
  github_repository    = var.github_repository
  github_repository_id = tostring(data.github_repository.self.repo_id)

  app_registrations = {
    dev = {
      display_name       = "crm-showcase-ci-dev"
      github_environment = "dev"
      description        = "CRM Showcase CI (dev environment). OIDC federation only."
    }
    test = {
      display_name       = "crm-showcase-ci-test"
      github_environment = "test"
      description        = "CRM Showcase CI (test environment). OIDC federation only."
    }
  }
}

module "github" {
  source = "./modules/github"

  repository = var.github_repository

  environments = {
    dev = {
      ci_client_id            = module.entra.client_ids["dev"]
      ci_tenant_id            = var.tenant_id
      powerplatform_env_id    = module.powerplatform.environment_ids["dev"]
      powerplatform_env_url   = module.powerplatform.environment_urls["dev"]
      allowed_branch_patterns = ["main"]
    }
    test = {
      ci_client_id            = module.entra.client_ids["test"]
      ci_tenant_id            = var.tenant_id
      powerplatform_env_id    = module.powerplatform.environment_ids["test"]
      powerplatform_env_url   = module.powerplatform.environment_urls["test"]
      allowed_branch_patterns = ["main"]
      reviewer_user_ids       = [data.github_user.owner.id]
      prevent_self_review     = false
    }
  }
}

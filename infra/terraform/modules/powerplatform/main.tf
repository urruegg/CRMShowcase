locals {
  environments_with_dv = {
    for k, v in var.environments : k => v
  }
}

resource "powerplatform_environment" "this" {
  for_each = local.environments_with_dv

  display_name     = each.value.display_name
  location         = each.value.location
  environment_type = each.value.env_type
  cadence          = each.value.cadence

  dataverse = {
    currency_code     = each.value.currency
    language_code     = each.value.language
    domain            = each.value.domain
    security_group_id = each.value.security_group_id == "" ? null : each.value.security_group_id
  }

  lifecycle {
    ignore_changes = [
      # environment_type is set at creation for trials and is not changeable.
      environment_type,
      # dataverse.security_group_id is often set out-of-band by tenant admins.
      dataverse.security_group_id,
      # Attributes not surfaced by the current provider version but managed by Microsoft.
      allow_bing_search,
      allow_moving_data_across_regions,
      dataverse.templates,
    ]
  }
}

resource "powerplatform_tenant_settings" "this" {
  power_platform = {
    power_apps = {
      disable_share_with_everyone              = var.tenant_settings.disable_share_with_everyone
      disable_connection_sharing_with_everyone = var.tenant_settings.disable_connection_sharing_everyone
    }
    intelligence = {
      disable_copilot               = var.tenant_settings.disable_copilot
      enable_open_ai_bot_publishing = var.tenant_settings.enable_openai_bot_publishing
    }
    licensing = {
      storage_capacity_consumption_warning_threshold = var.tenant_settings.storage_capacity_warning_threshold
    }
  }

  disable_environment_creation_by_non_admin_users = var.tenant_settings.disable_new_env_creation_non_admins
}

# NOTE: Adding a service principal as a Dataverse application user is not a
# Terraform-native operation in the current microsoft/power-platform provider
# (`powerplatform_user` treats service principals as pre-existing users and
# returns 404 when creating them from scratch). We use a script instead
# (`infra/scripts/add-ci-app-users.ps1`) as documented in ADR-0005. This is
# recorded here as a comment so the module's contract is clear.


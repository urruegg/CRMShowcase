provider "powerplatform" {
  use_cli   = true
  tenant_id = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
  use_cli   = true
}

provider "azurerm" {
  features {}
  tenant_id = var.tenant_id
  use_cli   = true

  subscription_id                 = var.azure_subscription_id
  resource_provider_registrations = "none"
}

provider "github" {
  owner = var.github_owner
}

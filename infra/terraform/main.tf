module "powerplatform" {
  source = "./modules/powerplatform"

  environments    = var.environments
  tenant_settings = var.tenant_settings
}

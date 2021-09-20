# Assign roles
resource "azurerm_role_assignment" "acr" {
  count                = length(var.container_registries)
  scope                = var.container_registries[count.index]
  role_definition_name = "AcrPull"
  principal_id         = var.service_principal.object_id
}

resource "azurerm_role_assignment" "subnet" {
  count                = length(local.agent_pool_subnets)
  scope                = local.agent_pool_subnets[count.index]
  role_definition_name = "Network Contributor"
  principal_id         = var.service_principal.object_id
}

resource "azurerm_role_assignment" "storage" {
  count                = length(var.storage_contributor)
  scope                = var.storage_contributor[count.index]
  role_definition_name = "Storage Account Contributor"
  principal_id         = var.service_principal.object_id
}

resource "azurerm_role_assignment" "msi" {
  count                = length(var.managed_identities)
  scope                = var.managed_identities[count.index]
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.service_principal.object_id

  # For now ignore changes for scope because of lower/upper case issue
  # with resourceId forces a recreate of this resource.
  lifecycle {
    ignore_changes = [scope]
  }
}

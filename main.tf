locals {
  default_agent_profile = {
    count                = 1
    vm_size              = "Standard_D1_v2"
    os_type              = "Linux"
    availability_zones   = null
    enable_auto_scaling  = false
    min_count            = null
    max_count            = null
    type                 = "VirtualMachineScaleSets"
    node_taints          = null
    orchestrator_version = null
  }

  default_linux_node_profile = {
    max_pods        = 30
    os_disk_size_gb = 60
  }

  default_windows_node_profile = {
    max_pods        = 20
    os_disk_size_gb = 200
  }

  agent_pools_with_defaults = [for ap in var.agent_pools :
    merge(local.default_agent_profile, ap)
  ]
  agent_pools = { for ap in local.agent_pools_with_defaults :
    ap.name => ap.os_type == "Linux" ? merge(local.default_linux_node_profile, ap) : merge(local.default_windows_node_profile, ap)
  }
  default_pool = var.agent_pools[0].name

  agent_pool_availability_zones_lb = [for ap in local.agent_pools : ap.availability_zones != null ? "Standard" : ""]
  load_balancer_sku                = coalesce(flatten([local.agent_pool_availability_zones_lb, ["Standard"]])...)

  # distinct and assigning subnets
  agent_pool_subnets = distinct([for ap in local.agent_pools : ap.vnet_subnet_id])
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                            = "${var.name}-aks"
  location                        = data.azurerm_resource_group.aks.location
  resource_group_name             = data.azurerm_resource_group.aks.name
  dns_prefix                      = var.name
  kubernetes_version              = var.kubernetes_version
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  node_resource_group             = var.node_resource_group
  enable_pod_security_policy      = var.enable_pod_security_policy

  dynamic "default_node_pool" {
    for_each = { for k, v in local.agent_pools : k => v if k == local.default_pool }
    iterator = ap
    content {
      name                 = ap.value.name
      node_count           = ap.value.count
      vm_size              = ap.value.vm_size
      availability_zones   = ap.value.availability_zones
      enable_auto_scaling  = ap.value.enable_auto_scaling
      min_count            = ap.value.min_count
      max_count            = ap.value.max_count
      max_pods             = ap.value.max_pods
      os_disk_size_gb      = ap.value.os_disk_size_gb
      type                 = ap.value.type
      vnet_subnet_id       = ap.value.vnet_subnet_id
      node_taints          = ap.value.node_taints
      orchestrator_version = ap.value.orchestrator_version
    }
  }

  service_principal {
    client_id     = var.service_principal.client_id
    client_secret = var.service_principal.client_secret
  }

  addon_profile {
    oms_agent {
      enabled                    = var.addons.oms_agent
      log_analytics_workspace_id = var.addons.oms_agent ? var.addons.oms_agent_workspace_id : null
    }

    kube_dashboard {
      enabled = var.addons.dashboard
    }

    azure_policy {
      enabled = var.addons.policy
    }
  }

  dynamic "linux_profile" {
    for_each = var.linux_profile != null ? [true] : []
    iterator = lp
    content {
      admin_username = var.linux_profile.username

      ssh_key {
        key_data = var.linux_profile.ssh_key
      }
    }
  }

  dynamic "windows_profile" {
    for_each = var.windows_profile != null ? [true] : []
    iterator = wp
    content {
      admin_username = var.windows_profile.username
      admin_password = var.windows_profile.password
    }
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = cidrhost(var.service_cidr, 10)
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = var.service_cidr

    load_balancer_sku = local.load_balancer_sku
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      client_app_id     = var.azure_active_directory.client_app_id
      server_app_id     = var.azure_active_directory.server_app_id
      server_app_secret = var.azure_active_directory.server_app_secret
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "aks" {
  for_each = { for k, v in local.agent_pools : k => v if k != local.default_pool }

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  availability_zones    = each.value.availability_zones
  enable_auto_scaling   = each.value.enable_auto_scaling
  node_count            = each.value.count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_type               = each.value.os_type
  vnet_subnet_id        = each.value.vnet_subnet_id
  node_taints           = each.value.node_taints
  orchestrator_version  = each.value.orchestrator_version
}

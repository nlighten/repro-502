resource "azurerm_kubernetes_cluster" "repro_502" {
  name                = "aks-repro-502"
  location            = azurerm_resource_group.repro_502.location
  resource_group_name = azurerm_resource_group.repro_502.name
  dns_prefix          = "repro-502"

  default_node_pool {
    name                         = "default"
    node_count                   = 3
    vm_size                      = var.vm_sku
    vnet_subnet_id               = azurerm_subnet.aks.id
    os_disk_type                 = var.vm_disk_type
    only_critical_addons_enabled = true
    temporary_name_for_rotation  = "defaulttmp"

    # linux_os_config {
    #   sysctl_config {
    #     net_netfilter_nf_conntrack_max = 262144
    #   }
    # }

  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = var.aks_network_plugin
    network_plugin_mode = var.aks_network_plugin == "azure" ? "overlay" : null
  }

}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.repro_502.id
  vm_size               = var.vm_sku
  node_count            = 3
  os_disk_type          = var.vm_disk_type

  # linux_os_config {
  #   sysctl_config {
  #     net_netfilter_nf_conntrack_max = 262144
  #   }
  # }

}

resource "azurerm_role_assignment" "aks_on_subnet" {
  role_definition_name = "Network Contributor"
  scope                = azurerm_virtual_network.repro_502.id
  principal_id         = azurerm_kubernetes_cluster.repro_502.identity[0].principal_id
}

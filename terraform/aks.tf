resource "azurerm_kubernetes_cluster" "repro_502" {
  name                = "aks-repro-502"
  location            = azurerm_resource_group.repro_502.location
  resource_group_name = azurerm_resource_group.repro_502.name
  dns_prefix          = "repro-502"

  default_node_pool {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_D4s_v5"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
  }

}

resource "azurerm_role_assignment" "aks_on_subnet" {
  role_definition_name = "Network Contributor"
  scope                = azurerm_virtual_network.repro_502.id
  principal_id         = azurerm_kubernetes_cluster.repro_502.identity[0].principal_id
}

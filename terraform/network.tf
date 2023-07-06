resource "azurerm_resource_group" "repro_502" {
  name     = "repro-502"
  location = "West Europe"
}

resource "azurerm_network_watcher" "repro_502" {
  name                = "NetworkWatcher_WestEurope"
  location            = azurerm_resource_group.repro_502.location
  resource_group_name = azurerm_resource_group.repro_502.name
}

resource "azurerm_virtual_network" "repro_502" {
  name                = "vnet-repro-502"
  location            = azurerm_resource_group.repro_502.location
  resource_group_name = azurerm_resource_group.repro_502.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "ingress" {
  name                 = "IngressSubnet"
  resource_group_name  = azurerm_resource_group.repro_502.name
  virtual_network_name = azurerm_virtual_network.repro_502.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "aks" {
  name                 = "AksSubnet"
  resource_group_name  = azurerm_resource_group.repro_502.name
  virtual_network_name = azurerm_virtual_network.repro_502.name
  address_prefixes     = ["10.10.1.0/24"]
}

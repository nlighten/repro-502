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

resource "azurerm_public_ip" "repro_502" {
  name                = "pip-repro-502"
  location            = azurerm_resource_group.repro_502.location
  resource_group_name = azurerm_resource_group.repro_502.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "repro_502" {
  name                = "ngw-repro-502"
  location            = azurerm_resource_group.repro_502.location
  resource_group_name = azurerm_resource_group.repro_502.name
}

resource "azurerm_nat_gateway_public_ip_association" "repro_502" {
  nat_gateway_id       = azurerm_nat_gateway.repro_502.id
  public_ip_address_id = azurerm_public_ip.repro_502.id
}

resource "azurerm_subnet_nat_gateway_association" "aks_subnet" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.repro_502.id

  depends_on = [ azurerm_nat_gateway_public_ip_association.repro_502 ]
}
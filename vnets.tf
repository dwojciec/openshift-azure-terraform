# ******* VNETS / SUBNETS ***********

resource "azurerm_virtual_network" "vnet" {
  name                = "openshiftvnet"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  address_space       = ["10.0.0.0/8"]
  depends_on          = ["azurerm_virtual_network.vnet"]
}

resource "azurerm_subnet" "master_subnet" {
  name                 = "mastersubnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "10.1.0.0/16"
  depends_on           = ["azurerm_virtual_network.vnet"]
}

resource "azurerm_subnet" "node_subnet" {
  name                 = "nodesubnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "10.2.0.0/16"
}

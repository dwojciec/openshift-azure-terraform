provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.aad_client_id}"
  client_secret   = "${var.aad_client_secret}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

# ******* AVAILABILITY SETS ***********

resource "azurerm_availability_set" "master" {
  name                = "ocp-master-instances"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  managed             = true
}

resource "azurerm_availability_set" "infra" {
  name                = "ocp-infra-instances"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  managed             = true
}

resource "azurerm_availability_set" "node" {
  name                = "ocp-app-instances"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  managed             = true
}

resource "azurerm_availability_set" "cns" {
  name                = "ocp-cns-instances"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  managed             = true
}

# ******* IP ADDRESSES ***********

resource "azurerm_public_ip" "bastion_pip" {
  name                         = "bastionpip"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  location                     = "${azurerm_resource_group.rg.location}"
  public_ip_address_allocation = "Static"
  domain_name_label            = "${var.openshift_cluster_prefix}-bastion"
}

resource "azurerm_public_ip" "openshift_master_pip" {
  name                         = "masterpip"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  location                     = "${azurerm_resource_group.rg.location}"
  public_ip_address_allocation = "Static"
  domain_name_label            = "${var.openshift_cluster_prefix}"
}

resource "azurerm_public_ip" "infra_lb_pip" {
  name                         = "infraip"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  location                     = "${azurerm_resource_group.rg.location}"
  public_ip_address_allocation = "Static"
  domain_name_label            = "${var.openshift_cluster_prefix}infrapip"
}

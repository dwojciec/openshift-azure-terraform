# ******* STORAGE ACCOUNTS ***********

resource "azurerm_storage_account" "bastion_storage_account" {
  name                     = "${var.openshift_cluster_prefix}bsa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"
}

resource "azurerm_storage_account" "master_storage_account" {
  name                     = "${var.openshift_cluster_prefix}msa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"
}

resource "azurerm_storage_account" "infra_storage_account" {
  name                     = "${var.openshift_cluster_prefix}infrasa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"
}

resource "azurerm_storage_account" "nodeos_storage_account" {
  name                     = "${var.openshift_cluster_prefix}nodeossa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"
}

resource "azurerm_storage_account" "cns_storage_account" {
  name                     = "${var.openshift_cluster_prefix}cnssa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"
}

resource "azurerm_storage_account" "nodedata_storage_account" {
  name                     = "${var.openshift_cluster_prefix}nodedatasa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"
}

resource "azurerm_storage_account" "registry_storage_account" {
  name                     = "${var.storage_account_name}regsa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"
}

resource "azurerm_storage_account" "persistent_volume_storage_account" {
  name                     = "${var.openshift_cluster_prefix}pvsa"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_account_replication_type}"
}

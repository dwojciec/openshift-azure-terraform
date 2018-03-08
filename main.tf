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
  name                = "masteravailabilityset"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
}

resource "azurerm_availability_set" "infra" {
  name                = "infraavailabilityset"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
}

resource "azurerm_availability_set" "node" {
  name                = "nodeavailabilityset"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
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












# ******* VM EXTENSIONS *******


# resource "azurerm_virtual_machine_extension" "deploy_open_shift_master" {
#   name                       = "masterOpShExt${count.index}"
#   location                   = "${azurerm_resource_group.rg.location}"
#   resource_group_name        = "${azurerm_resource_group.rg.name}"
#   virtual_machine_name       = "${element(azurerm_virtual_machine.master.*.name, count.index)}"
#   publisher                  = "Microsoft.Azure.Extensions"
#   type                       = "CustomScript"
#   type_handler_version       = "2.0"
#   auto_upgrade_minor_version = true
#   depends_on                 = ["azurerm_virtual_machine.master", "azurerm_virtual_machine_extension.node_prep", "azurerm_storage_container.vhds", "azurerm_virtual_machine_extension.deploy_infra"]
#
#   settings = <<SETTINGS
# {
#   "fileUris": [
# 		"${var.artifacts_location}scripts/masterPrep.sh",
#     "${var.artifacts_location}scripts/deployOpenShift.sh"
# 	]
# }
# SETTINGS
#
#   protected_settings = <<SETTINGS
#  {
#    "commandToExecute": "bash masterPrep.sh ${azurerm_storage_account.persistent_volume_storage_account.name} ${var.admin_username} && bash deployOpenShift.sh \"${var.admin_username}\" '${var.openshift_password}' \"${var.key_vault_secret}\" \"${var.openshift_cluster_prefix}-master\" \"${azurerm_public_ip.openshift_master_pip.fqdn}\" \"${azurerm_public_ip.openshift_master_pip.ip_address}\" \"${var.openshift_cluster_prefix}-infra\" \"${var.openshift_cluster_prefix}-node\" \"${var.node_instance_count}\" \"${var.infra_instance_count}\" \"${var.master_instance_count}\" \"${var.default_sub_domain_type}\" \"${azurerm_storage_account.registry_storage_account.name}\" \"${azurerm_storage_account.registry_storage_account.primary_access_key}\" \"${var.tenant_id}\" \"${var.subscription_id}\" \"${var.aad_client_id}\" \"${var.aad_client_secret}\" \"${azurerm_resource_group.rg.name}\" \"${azurerm_resource_group.rg.location}\" \"${var.key_vault_name}\""
#  }
# SETTINGS
# }


# resource "azurerm_virtual_machine_extension" "deploy_infra" {
#   name                       = "infraOpShExt${count.index}"
#   location                   = "${azurerm_resource_group.rg.location}"
#   resource_group_name        = "${azurerm_resource_group.rg.name}"
#   virtual_machine_name       = "${element(azurerm_virtual_machine.infra.*.name, count.index)}"
#   publisher                  = "Microsoft.Azure.Extensions"
#   type                       = "CustomScript"
#   type_handler_version       = "2.0"
#   auto_upgrade_minor_version = true
#   depends_on                 = ["azurerm_virtual_machine.infra"]
#
#   settings = <<SETTINGS
# {
#   "fileUris": [
# 		"${var.artifacts_location}scripts/nodePrep.sh"
# 	]
# }
# SETTINGS
#
#   protected_settings = <<SETTINGS
# {
# 	"commandToExecute": "bash nodePrep.sh"
# }
# SETTINGS
# }


# resource "azurerm_virtual_machine_extension" "node_prep" {
#   name                       = "nodePrepExt${count.index}"
#   location                   = "${azurerm_resource_group.rg.location}"
#   resource_group_name        = "${azurerm_resource_group.rg.name}"
#   virtual_machine_name       = "${element(azurerm_virtual_machine.node.*.name, count.index)}"
#   publisher                  = "Microsoft.Azure.Extensions"
#   type                       = "CustomScript"
#   type_handler_version       = "2.0"
#   auto_upgrade_minor_version = true
#   depends_on                 = ["azurerm_virtual_machine.node", "azurerm_storage_account.nodeos_storage_account"]
#
#   settings = <<SETTINGS
# {
#   "fileUris": [
# 		"${var.artifacts_location}scripts/nodePrep.sh"
# 	]
# }
# SETTINGS
#
#   protected_settings = <<SETTINGS
# {
# 	"commandToExecute": "bash nodePrep.sh"
# }
# SETTINGS
# }

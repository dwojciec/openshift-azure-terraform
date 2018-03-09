# ******* Bastion Host *******

resource "azurerm_virtual_machine" "bastion" {
  name                             = "${var.openshift_cluster_prefix}-bastion-0"
  location                         = "${azurerm_resource_group.rg.location}"
  resource_group_name              = "${azurerm_resource_group.rg.name}"
  network_interface_ids            = ["${azurerm_network_interface.bastion_nic.id}"]
  vm_size                          = "${var.bastion_vm_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  tags {
    displayName = "${var.openshift_cluster_prefix}-bastion VM Creation"
  }

 connection {
     type                = "ssh"
    host                 = "${azurerm_public_ip.bastion_pip.fqdn}"
    user                 = "${var.admin_username}"
    port                 = "22"
    private_key  = "${file(var.connection_private_ssh_key_path)}"
  }

provisioner "file" {
    source      = "${var.openshift_script_path}/bastionPrep.sh"
    destination = "bastionPrep.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod +x bastionPrep.sh",
      "sudo bash bastionPrep.sh \"${var.openshift_rht_user}\" \"${var.openshift_rht_password}\" \"${var.openshift_rht_poolid}\""
    ]
  }

  os_profile {
    computer_name  = "${var.openshift_cluster_prefix}-bastion-${count.index}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.openshift_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.ssh_public_key}"
    }
  }

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name          = "${var.openshift_cluster_prefix}-master-osdisk${count.index}"
    vhd_uri       = "${azurerm_storage_account.bastion_storage_account.primary_blob_endpoint}vhds/${var.openshift_cluster_prefix}-bastion-osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
    disk_size_gb  = 60
  }
}

resource "azurerm_virtual_machine_extension" "deploy_open_shift_bastion" {
  name                        = "bastionOpShExt"
   location                   = "${azurerm_resource_group.rg.location}"
   resource_group_name        = "${azurerm_resource_group.rg.name}"
   virtual_machine_name       = "${var.openshift_cluster_prefix}-bastion-0"
   publisher                  = "Microsoft.Azure.Extensions"
   type                       = "CustomScript"
   type_handler_version       = "2.0"
   auto_upgrade_minor_version = true
   depends_on                 = ["azurerm_virtual_machine.infra", "azurerm_virtual_machine.node" , "azurerm_virtual_machine.master"]

   settings = <<SETTINGS
 {
   "fileUris": [
     "${var.openshift_azure_deploy_openshift_script}"
 	]
 }
SETTINGS
#
   protected_settings = <<SETTINGS
  {
    "commandToExecute": "bash deployOpenShift.sh ${var.admin_username} ${var.openshift_password} ${base64encode(file(var.connection_private_ssh_key_path))} ${var.openshift_cluster_prefix}-master ${azurerm_public_ip.openshift_master_pip.fqdn} ${azurerm_public_ip.openshift_master_pip.ip_address} ${var.openshift_cluster_prefix}-infra ${var.openshift_cluster_prefix}-node ${var.node_instance_count} ${var.infra_instance_count} ${var.master_instance_count} ${azurerm_public_ip.infra_lb_pip.ip_address}.${var.default_sub_domain_type} ${var.openshift_cluster_prefix} ${azurerm_storage_account.registry_storage_account.name} ${azurerm_storage_account.registry_storage_account.primary_access_key} ${var.tenant_id} ${var.subscription_id} ${var.aad_client_id} ${var.aad_client_secret} ${azurerm_resource_group.rg.name} ${azurerm_resource_group.rg.location} ${var.key_vault_name} "
  }
 SETTINGS
 }

# ******* Node VMs *******

resource "azurerm_virtual_machine" "node" {
  name                             = "${var.openshift_cluster_prefix}-app-${count.index}"
  location                         = "${azurerm_resource_group.rg.location}"
  resource_group_name              = "${azurerm_resource_group.rg.name}"
  availability_set_id              = "${azurerm_availability_set.node.id}"
  network_interface_ids            = ["${element(azurerm_network_interface.node_nic.*.id, count.index)}"]
  vm_size                          = "${var.node_vm_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  count                            = "${var.node_instance_count}"

  tags {
    displayName = "${var.openshift_cluster_prefix}-node VM Creation"
    environment = "${var.environment}"
  }

  connection {
    type                = "ssh"
    bastion_host        = "${azurerm_public_ip.bastion_pip.fqdn}"
    bastion_user        = "${var.admin_username}"
    bastion_private_key = "${file(var.connection_private_ssh_key_path)}"
    host                = "${element(azurerm_network_interface.node_nic.*.private_ip_address, count.index)}"
    user                = "${var.admin_username}"
    private_key         = "${file(var.connection_private_ssh_key_path)}"
  }

  provisioner "file" {
    source      = "${var.openshift_script_path}/nodePrep.sh"
    destination = "nodePrep.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x nodePrep.sh",
      "sudo bash nodePrep.sh \"${var.openshift_rht_user}\" \"${var.openshift_rht_password}\" \"${var.openshift_rht_poolid}\"",
    ]
  }

  os_profile {
    computer_name  = "${var.openshift_cluster_prefix}-app-${count.index}"
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
    name              = "${var.openshift_cluster_prefix}-ocp-app-osdisk${count.index}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = 64
  }

storage_data_disk {
    name              = "${var.openshift_cluster_prefix}-ocp-app-datadisk-${count.index}"
    create_option     = "Empty"
    disk_size_gb      = 64
    managed_disk_type = "Premium_LRS"
    lun               = 0
  }

  storage_data_disk {
    name              = "${var.openshift_cluster_prefix}-ocp-app-container-${count.index}"
    create_option     = "Empty"
    disk_size_gb      = 64
    managed_disk_type = "Premium_LRS"
    lun               = 1
  }
}

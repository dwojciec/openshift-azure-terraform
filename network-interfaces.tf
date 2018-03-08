# ******* NETWORK INTERFACES ***********

resource "azurerm_network_interface" "bastion_nic" {
  name                      = "bastionnic${count.index}"
  location                  = "${azurerm_resource_group.rg.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.master_nsg.id}"

  ip_configuration {
    name                          = "bastionip${count.index}"
    subnet_id                     = "${azurerm_subnet.master_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bastion_pip.id}"
  }
}

resource "azurerm_network_interface" "master_nic" {
  name                      = "masternic${count.index}"
  location                  = "${azurerm_resource_group.rg.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.master_nsg.id}"
  count                     = "${var.master_instance_count}"

  ip_configuration {
    name                                    = "masterip${count.index}"
    subnet_id                               = "${azurerm_subnet.master_subnet.id}"
    private_ip_address_allocation           = "Dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.master_lb.id}"]
    load_balancer_inbound_nat_rules_ids     = ["${element(azurerm_lb_nat_rule.master_lb.*.id, count.index)}"]
  }
}

resource "azurerm_network_interface" "infra_nic" {
  name                      = "infra_nic${count.index}"
  location                  = "${azurerm_resource_group.rg.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.infra_nsg.id}"
  count                     = "${var.infra_instance_count}"

  ip_configuration {
    name                                    = "infraip${count.index}"
    subnet_id                               = "${azurerm_subnet.master_subnet.id}"
    private_ip_address_allocation           = "Dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.infra_lb.id}"]
  }
}

resource "azurerm_network_interface" "node_nic" {
  name                      = "node_nic${count.index}"
  location                  = "${azurerm_resource_group.rg.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.node_nsg.id}"
  count                     = "${var.node_instance_count}"

  ip_configuration {
    name                          = "nodeip${count.index}"
    subnet_id                     = "${azurerm_subnet.node_subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

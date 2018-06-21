# ******* NETWORK SECURITY GROUPS ***********

# ****** BASTION
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "${var.openshift_cluster_prefix}-bastion-nsg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "bastion-nsg-ssh"
    description                = "SSH access from Internet"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags {
       environment = "${var.environment}"
}
}

# ****** MASTER

resource "azurerm_network_security_group" "master_nsg" {
  name                = "${var.openshift_cluster_prefix}-master-nsg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "master-ssh"
    description                = "SSH from the bastion"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "master-etcd"
    description                = "ETCD service ports"
    priority                   = 525
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "master-api"
    description                = "API port - Allow HTTPS connections from all locations"
    priority                   = 550
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "master-api-lb"
    description                = "API port - LoadBalancer"
    priority                   = 575
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "master-ocp-tcp"
    description                = "TCP DNS and fluentd"
    priority                   = 600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8053-24224"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "master-ocp-udp"
    description                = "UDP DNS and fluentd"
    priority                   = 625
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "8053-24224"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "node-kubelet"
    description                = "kubelet"
    priority                   = 650
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "node-sdn"
    description                = "Openshift sdn"
    priority                   = 675
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4789"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
 tags {
       environment = "${var.environment}"
       sg = "master_security_group"
}
}
# ****** INFRA
resource "azurerm_network_security_group" "infra_nsg" {
  name                = "${var.openshift_cluster_prefix}-infra-nsg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "infra-ssh"
    description                = "ssh from the bastion" 
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "router-ports"
    description                = "Openshift router"
    priority                   = 525
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80-443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "infra-ports"
    description                = "Elasticsearch"
    priority                   = 550
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9200-9300"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "node-kubelet"
    description                = "kubelet"
    priority                   = 575
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "node-sdn"
    description                = "Openshift sdn"
    priority                   = 600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4789"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "router-ports-2"
    description                = "Openshift router 2"
    priority                   = 625
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80-443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"

}
 tags {
       environment = "${var.environment}"
       sg = "infra_security_group"
}
}
# ****** NODE
resource "azurerm_network_security_group" "node_nsg" {
  name                = "${var.openshift_cluster_prefix}-node-nsg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "node-ssh"
    description                = "SSH from the bastion"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "node-kubelet"
    description                = "kubelet"
    priority                   = 525
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "node-sdn"
    description                = "ElasticSearch and ocp apps"
    priority                   = 550
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4789"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
 tags {
       environment = "${var.environment}"
       sg = "node_security_group"
}
}

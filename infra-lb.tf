# ******* INFRA LOAD BALANCER ***********

resource "azurerm_lb" "infra_lb" {
  name                = "routerExternalLB"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  depends_on          = ["azurerm_public_ip.infra_lb_pip"]

  frontend_ip_configuration {
    name                 = "routerFrontEnd"
    public_ip_address_id = "${azurerm_public_ip.infra_lb_pip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "infra_lb" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  name                = "routerBackEnd"
  loadbalancer_id     = "${azurerm_lb.infra_lb.id}"
  depends_on          = ["azurerm_lb.infra_lb"]
}

resource "azurerm_lb_probe" "infra_lb_http_probe" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.infra_lb.id}"
  name                = "routerHealthProbe"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
  protocol            = "Tcp"
  depends_on          = ["azurerm_lb.infra_lb"]
}

resource "azurerm_lb_probe" "infra_lb_https_probe" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.infra_lb.id}"
  name                = "httpsProbe"
  port                = 443
  interval_in_seconds = 5
  number_of_probes    = 2
  protocol            = "Tcp"
}

resource "azurerm_lb_probe" "infra_lb_cockpit_probe" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.infra_lb.id}"
  name                = "cockpitProbe"
  port                = 9090
  interval_in_seconds = 5
  number_of_probes    = 2
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "infra_lb_http" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.infra_lb.id}"
  name                           = "routerRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  load_distribution              = "SourceIPProtocol"
  frontend_ip_configuration_name = "routerFrontEnd"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.infra_lb.id}"
  probe_id                       = "${azurerm_lb_probe.infra_lb_http_probe.id}"
  depends_on                     = ["azurerm_lb_probe.infra_lb_http_probe", "azurerm_lb.infra_lb", "azurerm_lb_backend_address_pool.infra_lb"]
}

resource "azurerm_lb_rule" "infra_lb_https" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.infra_lb.id}"
  name                           = "httpsRouterRule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  load_distribution              = "SourceIPProtocol"
  frontend_ip_configuration_name = "routerFrontEnd"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.infra_lb.id}"
  probe_id                       = "${azurerm_lb_probe.infra_lb_https_probe.id}"
  depends_on                     = ["azurerm_lb_probe.infra_lb_https_probe", "azurerm_lb_backend_address_pool.infra_lb"]
}

resource "azurerm_lb_rule" "infra_lb_cockpit" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.infra_lb.id}"
  name                           = "CockpitConsole"
  protocol                       = "Tcp"
  frontend_port                  = 9090
  backend_port                   = 9090
  frontend_ip_configuration_name = "routerFrontEnd"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.infra_lb.id}"
  probe_id                       = "${azurerm_lb_probe.infra_lb_cockpit_probe.id}"
  depends_on                     = ["azurerm_lb_probe.infra_lb_cockpit_probe", "azurerm_lb_backend_address_pool.infra_lb"]
}

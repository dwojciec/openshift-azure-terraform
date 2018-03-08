output "openshift_console_url" {
  value = "https://${azurerm_public_ip.openshift_master_pip.fqdn}:8443/console"
}

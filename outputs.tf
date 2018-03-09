output "openshift_console_url" {
  value = "https://${azurerm_public_ip.openshift_master_pip.fqdn}:8443/console"
}
output "bastion_ssh" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.bastion_pip.fqdn"
}


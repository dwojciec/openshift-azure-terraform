variable "ssh_public_key" {
	default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiOIB0PTSuI8Sdes/ExSakdjPiqly54rfD3KN/5jNgVJ7y+WQv24oa6gQjU5qeT0NeWdjP9ZRJ/1KYt6sofZSwHKpaHq9R6xNjiFJdiymWF7sYfN/LWD0VwFyFIHEuo8SpsENHbw43gsp5/NzgO5PVLoloMOWnJKpdK6GODG/yepY0XD5nB9SYmcYqVzsOx21l9Y2To+q9ltsZy6pUtJKSp6Twyc+CXOVbTQAvfwBLMDPQH4qPXaXOsxYo4ISELHFKMGA27Tyh59FELU0t/6xLw9q9jr+ugkT1eHKIev2jJMyQlAD4N62HkRnpKpQv0nSZKAVr41w7IOjiPjZwm8qHmsv5Y10RieZf0+Rx3fUasWxEQJrUr4wTqz807717tGvATg/Um17qyQwahsodpxgHItyZoB80oMNo22vj9fNwLxkXsFr/UrtAa3+CgUJ1DYr5cJOq/mEvCtoUH7I16OFuTVZjJ5zYiU6Xq5L+z6844O1K/Dbi0DBEpmcnZtdvZX9sS+XFqV5KFkw8FXfb1mb+um3wvi4Wsyz6M1S7SfZqU6vPTCt41zHUAn/h+BdQTud9PkJ8ZCWYS0QU+7ehsqYI2rfCi+zl4yEdntZ3aVq833xZuPFngZNKEJl16MHz40Q+kTyDP/u7VeVWN/0xAnh3WDHZyV4q/abeVtnL0xUpkw== dwojciec@redhat.com"
}

variable "resource_group_name" {
  description = "Name of the azure resource group in which you will deploy this template."
}

variable "resource_group_location" {
  description = "Location of the azure resource group."
  default     = "WestEurope"
}

variable "subscription_id" {
  description = "Subscription ID of the key vault"
}

variable "openshift_rht_user" {
  description = "RHT USER"
}

variable "openshift_rht_password" {
  description = "RHT PASSWORD"
}

variable "openshift_rht_poolid" {
  description = "RHT POOLID"
}

variable "tenant_id" {
  description = "Tenant ID with access to your key vault and subscription"
}

variable "openshift_script_path" {
  description = "Local path to openshift scripts to prep nodes and install openshift origin"
}

variable "os_image" {
  description = "Select from CentOS (centos) or RHEL (rhel) for the Operating System"
  default     = "rhel"
}

variable "bastion_vm_size" {
  description = "Size of the Bastion Virtual Machine. Allowed values: Standard_A4, Standard_A5, Standard_A6, Standard_A7, Standard_A8, Standard_A9, Standard_A10, Standard_A11, Standard_D1, Standard_D2, Standard_D3, Standard_D4, Standard_D11, Standard_D12, Standard_D13, Standard_D14, Standard_D1_v2, Standard_D2_v2, Standard_D3_v2, Standard_D4_v2, Standard_D5_v2, Standard_D11_v2, Standard_D12_v2, Standard_D13_v2, Standard_D14_v2, Standard_G1, Standard_G2, Standard_G3, Standard_G4, Standard_G5, Standard_D1_v2, Standard_DS2, Standard_DS3, Standard_DS4, Standard_DS11, Standard_DS12, Standard_DS13, Standard_DS14, Standard_DS1_v2, Standard_DS2_v2, Standard_DS3_v2, Standard_DS4_v2, Standard_DS5_v2, Standard_DS11_v2, Standard_DS12_v2, Standard_DS13_v2, Standard_DS14_v2, Standard_GS1, Standard_GS2, Standard_GS3, Standard_GS4, Standard_GS5"
  default     = "Standard_D2_v2"
}

variable "master_vm_size" {
  description = "Size of the Master Virtual Machine. Allowed values: Standard_A4, Standard_A5, Standard_A6, Standard_A7, Standard_A8, Standard_A9, Standard_A10, Standard_A11, Standard_D1, Standard_D2, Standard_D3, Standard_D4, Standard_D11, Standard_D12, Standard_D13, Standard_D14, Standard_D1_v2, Standard_D2_v2, Standard_D3_v2, Standard_D4_v2, Standard_D5_v2, Standard_D11_v2, Standard_D12_v2, Standard_D13_v2, Standard_D14_v2, Standard_G1, Standard_G2, Standard_G3, Standard_G4, Standard_G5, Standard_D1_v2, Standard_DS2, Standard_DS3, Standard_DS4, Standard_DS11, Standard_DS12, Standard_DS13, Standard_DS14, Standard_DS1_v2, Standard_DS2_v2, Standard_DS3_v2, Standard_DS4_v2, Standard_DS5_v2, Standard_DS11_v2, Standard_DS12_v2, Standard_DS13_v2, Standard_DS14_v2, Standard_GS1, Standard_GS2, Standard_GS3, Standard_GS4, Standard_GS5"
  default     = "Standard_DS11_v2_Promo"
}

variable "infra_vm_size" {
  description = "Size of the Infra Virtual Machine. Allowed values: Standard_A4, Standard_A5, Standard_A6, Standard_A7, Standard_A8, Standard_A9, Standard_A10, Standard_A11,Standard_D1, Standard_D2, Standard_D3, Standard_D4,Standard_D11, Standard_D12, Standard_D13, Standard_D14,Standard_D1_v2, Standard_D2_v2, Standard_D3_v2, Standard_D4_v2, Standard_D5_v2,Standard_D11_v2, Standard_D12_v2, Standard_D13_v2, Standard_D14_v2,Standard_G1, Standard_G2, Standard_G3, Standard_G4, Standard_G5,Standard_D1_v2, Standard_DS2, Standard_DS3, Standard_DS4,Standard_DS11, Standard_DS12, Standard_DS13, Standard_DS14,Standard_DS1_v2, Standard_DS2_v2, Standard_DS3_v2, Standard_DS4_v2, Standard_DS5_v2,Standard_DS11_v2, Standard_DS12_v2, Standard_DS13_v2, Standard_DS14_v2,Standard_GS1, Standard_GS2, Standard_GS3, Standard_GS4, Standard_GS5"
  default     = "Standard_DS11_v2_Promo"
}

variable "node_vm_size" {
  description = "Size of the Node Virtual Machine. Allowed values: Standard_A4, Standard_A5, Standard_A6, Standard_A7, Standard_A8, Standard_A9, Standard_A10, Standard_A11, Standard_D1, Standard_D2, Standard_D3, Standard_D4, Standard_D11, Standard_D12, Standard_D13, Standard_D14, Standard_D1_v2, Standard_D2_v2, Standard_D3_v2, Standard_D4_v2, Standard_D5_v2, Standard_D11_v2, Standard_D12_v2, Standard_D13_v2, Standard_D14_v2, Standard_G1, Standard_G2, Standard_G3, Standard_G4, Standard_G5, Standard_D1_v2, Standard_DS2, Standard_DS3, Standard_DS4, Standard_DS11, Standard_DS12, Standard_DS13, Standard_DS14, Standard_DS1_v2, Standard_DS2_v2, Standard_DS3_v2, Standard_DS4_v2, Standard_DS5_v2, Standard_DS11_v2, Standard_DS12_v2, Standard_DS13_v2, Standard_DS14_v2, Standard_GS1, Standard_GS2, Standard_GS3, Standard_GS4, Standard_GS5"
  default     = "Standard_DS11_v2_Promo"
}

variable "storage_account_tier" {
  description = "This is the storage account Tier to create. Possible values include Standard and Premium."
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "This is the storage account Tier that you will need based on the vm size that you choose (value constraints)"
  default     = "LRS"
}

variable "os_image_map" {
  description = "os image map"
  type        = "map"

  default = {
    rhel_publisher   = "RedHat"
    rhel_offer       = "RHEL"
    rhel_sku         = "7-RAW"
    rhel_version     = "latest"
  }
}

variable "disk_size_gb" {
  description = "storage os disk size"
  default     = 60
}

variable "openshift_cluster_prefix" {
  description = "Cluster Prefix used to configure domain name label and hostnames for all nodes - master, infra and nodes. Between 1 and 20 characters"
}

variable "master_instance_count" {
  description = "Number of OpenShift Masters nodes to deploy. 1 is non HA and 3 is for HA."
  default     = 1
}

variable "infra_instance_count" {
  description = "Number of OpenShift infra nodes to deploy. 1 is non HA.  Choose 2 or 3 for HA."
  default     = 1
}

variable "node_instance_count" {
  description = "Number of OpenShift nodes to deploy. Allowed values: 1-30"
  default     = 1
}

variable "data_disk_size" {
  description = "Size of data disk to attach to nodes for Docker volume - valid sizes are 128 GB, 512 GB and 1023 GB"
  default     = 128
}

variable "admin_username" {
  description = "Admin username for both OS login and OpenShift login"
  default     = "ocpadmin"
}

variable "openshift_password" {
  description = "Password for OpenShift login"
}

variable "connection_private_ssh_key_path" {
  description = "Path to the private ssh key used to connect to machines within the OpenShift cluster."
}

variable "key_vault_resource_group" {
  description = "The name of the Resource Group that contains the Key Vault"
}

variable "key_vault_name" {
  description = "The name of the Key Vault you will use"
}

variable "key_vault_secret" {
  description = "The Secret Name you used when creating the Secret (that contains the Private Key)"
}

variable "aad_client_id" {
  description = "Azure Active Directory Client ID also known as Application ID for Service Principal"
}

variable "aad_client_secret" {
  description = "Azure Active Directory Client Secret for Service Principal"
}

variable "default_sub_domain_type" {
  description = "This will either be 'xipio' (if you don't have your own domain) or 'custom' if you have your own domain that you would like to use for routing"
  default     = "xip.io"
}

variable "default_sub_domain" {
  description = "The wildcard DNS name you would like to use for routing if you selected 'custom' above. If you selected 'xipio' above, then this field will be ignored"
  default     = "contoso.com"
}

variable "openshift_azure_deploy_openshift_script" {
 type        = "string"
  description = "URL for Deploy Openshift script"
  default     = "https://raw.githubusercontent.com/dwojciec/openshift-azure-terraform/master/openshift-enterprise/scripts/deployOpenShift.sh"
}
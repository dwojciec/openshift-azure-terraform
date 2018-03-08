
Deploy OpenShift Enterprise v3.7 on Azure using Terraform and Ansible
==================

This script allow you to deploy an OpenShift Enterprise v3.7.0 in best practices on Microsoft Azure.

Terraform Usage
==================

#### WARNING: Be sure that you are not overriding existing Azure resources that are in use. This Terraform process will create a resource group to contain all dependent resources within. This makes it easy to cleanup.

Preparation Steps
-----------------
* It is assumed that you have a functioning Azure client installed. You can do so [here](https://github.com/Azure/azure-cli)

* Install [Terraform](https://www.terraform.io/downloads.html) and create credentials for Terraform to access Azure. To do so, you will need to following environment variables :

  * ARM_SUBSCRIPTION_ID=<subscription id>
  * ARM_CLIENT_ID=<client id>
  * ARM_CLIENT_SECRET=<cient secret>
  * ARM_TENANT_ID=<tenant id>

* You can also fill the following values in the tfvars file if you prefeer.

* The values for the above environment variables can be obtained through the Azure CLI.

[Click here to get the step by step about it](https://github.com/sozercan/OpenShift-Azure-Terraform/blob/master/docs/CreateAzureSpn.md)

Deploy the Azure infrastructure and OpenShift
---------------------------------------------

* First rename the `terraform.tfvars.example` to `terraform.tfvars` and review the default configuration. Most common options are available inside. The full list of available options are in `config.tf`. 

* Update `terraform.tfvars` with the path to your passwordless SSH public and private keys. (ssh_public_key and connection_private_ssh_key_path)

* Change `openshift_azure_resource_prefix` (and optionally `openshift_azure_resource_suffix`) to something unique

* Optionally, customize the `master_instance_count` (default 1), the `node_instance_count` (default 1) and `infra_instance_count` for master (default 1), the bastion host size is Standard_D2_v2 and for the others VM is Standard_DS11_v2_Promo per default, but you can change it for your need.

* Create the OpenShift cluster by executing:
```bash
$ EXPORT ARM_SUBSCRIPTION_ID=<your subscription id>
$ EXPORT ARM_CLIENT_ID=<your client id>
$ EXPORT ARM_CLIENT_SECRET=<your cient secret>
$ EXPORT ARM_TENANT_ID=<your tenant id>

$ cd <repo> && terraform apply
```
### Connection to console

After your deployment your should be able to reach the OS console

```https://<masterFQDN>.<location>.cloudapp.azure.com:8443/console```

The cluster will use self-signed certificates. Accept the warning and proceed to the login page.


 ADDITIONAL
-------------
### Cleanup

To restart and cleanup the Azure assets run the following commands from the <repo> directory

```bash
$ az group delete <yourResourceGroup>
info:    Executing command group delete
Delete resource group <yourResourceGroup>? [y/n] y
+ Deleting resource group <yourResourceGroup>
info:    group delete command OK

$ cd <repo> && rm *terraform.tfstate

```

### Troubleshooting

If the deployment gets in an inconsistent state (repeated `terraform apply` commands fail, or output references to leases that no longer exist), you may need to manually reconcile. Destroy the `<yourResourceGroup>` resource group, run `terraform remote config -disable` and delete all `terraform.tfstate*` files from `os`, follow the above instructions again.

During the OCP installation you can check from the bastion host the content of /var/lib/waagent/custom-script/download/0 directory and the 2 files stdout and stderr.


#!/bin/bash

echo $(date) " - Starting Script"

set -e

SUDOUSER=$1
PASSWORD="$2"
PRIVATEKEY=$3
MASTER=$4
MASTERPUBLICIPHOSTNAME=$5
MASTERPUBLICIPADDRESS=$6
INFRA=$7
NODE=$8
NODECOUNT=$9
INFRACOUNT=${10}
MASTERCOUNT=${11}
ROUTING=${12}
# ${var.openshift_cluster_prefix}
OCP=${13}
BASTION=$(hostname -f)
REGISTRY_STORAGE_ACCOUNT_NAME=${14}
PRIMARY_ACCESS_KEY=${15}

TENANTID=${16}
SUBSCRIPTIONID=${17}
AADCLIENTID=${18}
AADCLIENTSECRET=${19}
RESOURCEGROUP=${20}
LOCATION=${21}
CNSCOUNT=${22}
CNS=${23}
ACCOUNTKEY_REGISTRY=${24}



MASTERLOOP=$((MASTERCOUNT - 1))
NODELOOP=$((NODECOUNT - 1))
INFRALOOP=$((INFRACOUNT -1))

DOMAIN=$( awk 'NR==2' /etc/resolv.conf | awk '{ print $2 }' )
echo " Print variable entry :"
echo " 1- SUDOUSER: " $SUDOUSER
echo " 2- PASSWORD:" $PASSWORD
echo " 3- PRIVATKEY: " $PRIVATEKEY
echo " 4-MASTER:" $MASTER
echo " 5-MASTERPUBLICIPHOSTNAME" $MASTERPUBLICIPHOSTNAME
echo " 6-MASTERPUBLICIPADDRESS" $MASTERPUBLICIPADDRESS
echo " 7 INFRA:" $INFRA
echo " 8 - NODE:" $NODE
echo " 9-NODECOUNT : " $NODECOUNT
echo " 10 -INFRACOUNT : " $INFRACOUNT
echo " 11 - MASTERCOUNT:" $MASTERCOUNT
echo " 12 - ROUTING:" $ROUTING
echo " 13 - OCP :" $OCP

echo "14 - REGISTRY_STORAGE_ACCOUNT_NAME:" $REGISTRY_STORAGE_ACCOUNT_NAME
echo "15 - PRIMARY_ACCESS_KEY:" $PRIMARY_ACCESS_KEY
echo "16 - TENANTID:" $TENANTID 
echo "17 - SUBSCRIPTIONID: "$SUBSCRIPTIONID
echo "18 - AADCLIENTID:" $AADCLIENTID
echo "19 - AADCLIENTSECRET:" $AADCLIENTSECRET
echo "20 - RESOURCEGROUP:" $RESOURCEGROUP
echo "21 - LOCATION:" $LOCATION
echo "22 - CNSCOUNT:" $CNSCOUNT
echo "23 - CNS:" $CNS
echo "24 - ACCOUNTKEY_REGISTRY:" $ACCOUNTKEY_REGISTRY
# Generate private keys for use by Ansible
echo $(date) " - Generating Private keys for use by Ansible for OpenShift Installation"

echo "Generating Private Keys"
runuser -l $SUDOUSER -c "(echo \"$PRIVATEKEY\" | base64 -d) > ~/.ssh/id_rsa"
runuser -l $SUDOUSER -c "chmod 600 ~/.ssh/id_rsa*"

echo "Configuring SSH ControlPath to use shorter path name"

sed -i -e "s/^# control_path = %(directory)s\/%%h-%%r/control_path = %(directory)s\/%%h-%%r/" /etc/ansible/ansible.cfg
sed -i -e "s/^#host_key_checking = False/host_key_checking = False/" /etc/ansible/ansible.cfg
sed -i -e "s/^#pty=False/pty=False/" /etc/ansible/ansible.cfg

# Create Ansible Playbook for Post Installation task
echo $(date) " - Create Ansible Playbook for Post Installation task"

# Run on all nodes
cat > /home/${SUDOUSER}/preinstall.yml <<EOF
---
- hosts: nodes
  remote_user: ${SUDOUSER}
  become: yes
  become_method: sudo
  vars:
    description: "Create /etc/hosts file"
  tasks:
  - name: copy hosts file
    copy:
      src: /tmp/hosts
      dest: /etc/hosts
      owner: root
      group: root
      mode: 0644
EOF

# Run on all masters
cat > /home/${SUDOUSER}/postinstall.yml <<EOF
---
- hosts: masters
  remote_user: ${SUDOUSER}
  become: yes
  become_method: sudo
  vars:
    description: "Create OpenShift Users"
  tasks:
  - name: create directory
    file: path=/etc/origin/master state=directory
  - name: add initial OpenShift user
    shell: htpasswd -cb /etc/origin/master/htpasswd ${SUDOUSER} "${PASSWORD}"
EOF

# Run on only MASTER-0
cat > /home/${SUDOUSER}/postinstall2.yml <<EOF
---
- hosts: nfs
  remote_user: ${SUDOUSER}
  become: yes
  become_method: sudo
  vars:
    description: "Make user cluster admin"
  tasks:
  - name: make OpenShift user cluster admin
    shell: oadm policy add-cluster-role-to-user cluster-admin $SUDOUSER --config=/etc/origin/master/admin.kubeconfig
EOF

# Run on all nodes
cat > /home/${SUDOUSER}/postinstall3.yml <<EOF
---
- hosts: nodes
  remote_user: ${SUDOUSER}
  become: yes
  become_method: sudo
  vars:
    description: "Set password for Cockpit"
  tasks:
  - name: configure Cockpit password
    shell: echo "${PASSWORD}"|passwd root --stdin
EOF

# Run on MASTER-0 - configure registry to use Azure Storage
cat > /home/${SUDOUSER}/dockerregistry.yml <<EOF
---
- hosts: master0
  gather_facts: no
  remote_user: ${SUDOUSER}
  become: yes
  become_method: sudo
  vars:
    description: "Set registry to use Azure Storage"
  tasks:
  - name: Configure docker-registry to use Azure Storage
    shell: oc env dc docker-registry -e REGISTRY_STORAGE=azure -e REGISTRY_STORAGE_AZURE_ACCOUNTNAME=$REGISTRYSA -e REGISTRY_STORAGE_AZURE_ACCOUNTKEY=$ACCOUNTKEY -e REGISTRY_STORAGE_AZURE_CONTAINER=registry
EOF

# Run on MASTER-0 - configure Storage Class

cat > /home/${SUDOUSER}/configurestorageclass.yml <<EOF
---
- hosts: master0
  gather_facts: no
  remote_user: ${SUDOUSER}
  become: yes
  become_method: sudo
  vars:
    description: "Create Storage Class"
  tasks:
  - name: Create Storage Class with StorageAccountPV1
    shell: oc create -f /home/${SUDOUSER}/scgeneric1.yml
EOF

# Create vars.yml file for use by setup-azure-config.yml playbook

cat > /home/${SUDOUSER}/vars.yml <<EOF
g_tenantId: $TENANTID
g_subscriptionId: $SUBSCRIPTIONID
g_aadClientId: $AADCLIENTID
g_aadClientSecret: $AADCLIENTSECRET
g_resourceGroup: $RESOURCEGROUP
g_location: $LOCATION
EOF

# Create Azure Cloud Provider configuration Playbook for Master Config

if [ $MASTERCOUNT -eq 1 ]
then

# Single Master Configuration

cat > /home/${SUDOUSER}/setup-azure-master.yml <<EOF
#!/usr/bin/ansible-playbook
- hosts: masters
  gather_facts: no
  serial: 1
  vars_files:
  - vars.yml
  become: yes
  vars:
    azure_conf_dir: /etc/origin/cloudprovider
    azure_conf: "{{ azure_conf_dir }}/azure.conf"
    master_conf: /etc/origin/master/master-config.yaml
  handlers:
  - name: restart origin-master-api
    systemd:
      state: restarted
      name: origin-master-api
  - name: restart origin-master-controllers
    systemd:
      state: restarted
      name: origin-master-controllers
  post_tasks:
  - name: make sure /etc/azure exists
    file:
      state: directory
      path: "{{ azure_conf_dir }}"
  - name: populate /etc/origin/cloudprovider/azure.conf
    copy:
      dest: "{{ azure_conf }}"
      content: |
        {
          "aadClientID" : "{{ g_aadClientId }}",
          "aadClientSecret" : "{{ g_aadClientSecret }}",
          "subscriptionID" : "{{ g_subscriptionId }}",
          "tenantID" : "{{ g_tenantId }}",
          "aadTenantID" : "{{ g_tenantId }}",
          "resourceGroup": "{{ g_resourceGroup }}",
          "location": "{{ g_location }}",
          "cloud": "AzurePublicCloud",
          "vnetName": "openshiftvnet:,
          "securityGroupName": "node-nsg",
          "primaryAvailabilitySetName": "ocp-app-instances"
        }
    notify:
    - restart origin-master-api
    - restart origin-master-controllers
  - name: insert the azure disk config into the master
    modify_yaml:
      dest: "{{ master_conf }}"
      yaml_key: "{{ item.key }}"
      yaml_value: "{{ item.value }}"
    with_items:
    - key: kubernetesMasterConfig.apiServerArguments.cloud-config
      value:
      - "{{ azure_conf }}"
    - key: kubernetesMasterConfig.apiServerArguments.cloud-provider
      value:
      - azure
    - key: kubernetesMasterConfig.controllerArguments.cloud-config
      value:
      - "{{ azure_conf }}"
    - key: kubernetesMasterConfig.controllerArguments.cloud-provider
      value:
      - azure
    notify:
    - restart origin-master-api
    - restart origin-master-controllers
EOF

else

# Multiple Master Configuration

cat > /home/${SUDOUSER}/setup-azure-master.yml <<EOF
#!/usr/bin/ansible-playbook
- hosts: masters
  gather_facts: no
  serial: 1
  vars_files:
  - vars.yml
  become: yes
  vars:
    azure_conf_dir: /etc/origin/cloudprovider
    azure_conf: "{{ azure_conf_dir }}/azure.conf"
    master_conf: /etc/origin/master/master-config.yaml
  handlers:
  - name: restart origin-master-api
    systemd:
      state: restarted
      name: origin-master-api
  - name: restart origin-master-controllers
    systemd:
      state: restarted
      name: origin-master-controllers
  post_tasks:
  - name: make sure /etc/azure exists
    file:
      state: directory
      path: "{{ azure_conf_dir }}"
  - name: populate /etc/origin/cloudprovider/azure.conf
    copy:
      dest: "{{ azure_conf }}"
      content: |
        {
          "aadClientID" : "{{ g_aadClientId }}",
          "aadClientSecret" : "{{ g_aadClientSecret }}",
          "subscriptionID" : "{{ g_subscriptionId }}",
          "tenantID" : "{{ g_tenantId }}",
          "resourceGroup": "{{ g_resourceGroup }}",
        }
    notify:
    - restart origin-master-api
    - restart origin-master-controllers
  - name: insert the azure disk config into the master
    modify_yaml:
      dest: "{{ master_conf }}"
      yaml_key: "{{ item.key }}"
      yaml_value: "{{ item.value }}"
    with_items:
    - key: kubernetesMasterConfig.apiServerArguments.cloud-config
      value:
      - "{{ azure_conf }}"
    - key: kubernetesMasterConfig.apiServerArguments.cloud-provider
      value:
      - azure
    - key: kubernetesMasterConfig.controllerArguments.cloud-config
      value:
      - "{{ azure_conf }}"
    - key: kubernetesMasterConfig.controllerArguments.cloud-provider
      value:
      - azure
    notify:
    - restart origin-master-api
    - restart origin-master-controllers
EOF

fi

# Create Azure Cloud Provider configuration Playbook for Node Config (Master Nodes)

cat > /home/${SUDOUSER}/setup-azure-node-master.yml <<EOF
#!/usr/bin/ansible-playbook
- hosts: masters
  serial: 1
  gather_facts: no
  vars_files:
  - vars.yml
  become: yes
  vars:
    azure_conf_dir: /etc/origin/cloudprovider
    azure_conf: "{{ azure_conf_dir }}/azure.conf"
    node_conf: /etc/origin/node/node-config.yaml
  handlers:
  - name: restart origin-node
    systemd:
      state: restarted
      name: origin-node
  post_tasks:
  - name: make sure /etc/azure exists
    file:
      state: directory
      path: "{{ azure_conf_dir }}"
  - name: populate /etc/origin/cloudprovider/azure.conf
    copy:
      dest: "{{ azure_conf }}"
      content: |
        {
          "aadClientID" : "{{ g_aadClientId }}",
          "aadClientSecret" : "{{ g_aadClientSecret }}",
          "subscriptionID" : "{{ g_subscriptionId }}",
          "tenantID" : "{{ g_tenantId }}",
          "resourceGroup": "{{ g_resourceGroup }}",
        }
    notify:
    - restart origin-node
  - name: insert the azure disk config into the node
    modify_yaml:
      dest: "{{ node_conf }}"
      yaml_key: "{{ item.key }}"
      yaml_value: "{{ item.value }}"
    with_items:
    - key: kubeletArguments.cloud-config
      value:
      - "{{ azure_conf }}"
    - key: kubeletArguments.cloud-provider
      value:
      - azure
    notify:
    - restart origin-node
EOF

# Create Azure Cloud Provider configuration Playbook for Node Config (Non-Master Nodes)

cat > /home/${SUDOUSER}/setup-azure-node.yml <<EOF
#!/usr/bin/ansible-playbook
- hosts: nodes:!masters
  serial: 1
  gather_facts: no
  vars_files:
  - vars.yml
  become: yes
  vars:
    azure_conf_dir: /etc/origin/cloudprovider
    azure_conf: "{{ azure_conf_dir }}/azure.conf"
    node_conf: /etc/origin/node/node-config.yaml
  handlers:
  - name: restart origin-node
    systemd:
      state: restarted
      name: origin-node
  post_tasks:
  - name: make sure /etc/azure exists
    file:
      state: directory
      path: "{{ azure_conf_dir }}"
  - name: populate /etc/origin/cloudprovider/azure.conf
    copy:
      dest: "{{ azure_conf }}"
      content: |
        {
          "aadClientID" : "{{ g_aadClientId }}",
          "aadClientSecret" : "{{ g_aadClientSecret }}",
          "subscriptionID" : "{{ g_subscriptionId }}",
          "tenantID" : "{{ g_tenantId }}",
          "resourceGroup": "{{ g_resourceGroup }}",
        }
    notify:
    - restart origin-node
  - name: insert the azure disk config into the node
    modify_yaml:
      dest: "{{ node_conf }}"
      yaml_key: "{{ item.key }}"
      yaml_value: "{{ item.value }}"
    with_items:
    - key: kubeletArguments.cloud-config
      value:
      - "{{ azure_conf }}"
    - key: kubeletArguments.cloud-provider
      value:
      - azure
    notify:
    - restart origin-node
  - name: delete the node so it can recreate itself
    command: oc delete node {{inventory_hostname}}
    delegate_to: ${MASTER}-0
  - name: sleep to let node come back to life
    pause:
       seconds: 90
EOF

# Create Playbook to delete stuck Master nodes and set as not schedulable

cat > /home/${SUDOUSER}/deletestucknodes.yml <<EOF
- hosts: masters
  gather_facts: no
  become: yes
  vars:
    description: "Delete stuck nodes"
  tasks:
  - name: Delete stuck nodes so it can recreate itself
    command: oc delete node {{inventory_hostname}}
    delegate_to: ${MASTER}-0
  - name: sleep between deletes
    pause:
      seconds: 25
  - name: set masters as unschedulable
    command: oadm manage-node {{inventory_hostname}} --schedulable=false
EOF

# Run on all masters
cat > /home/${SUDOUSER}/postinstall4.yml <<EOF
---
- hosts: masters
  remote_user: ${SUDOUSER}
  become: yes
  become_method: sudo
  vars:
    description: "Unset default registry DNS name"
  tasks:
  - name: copy atomic-openshift-master file
    copy:
      src: /tmp/atomic-openshift-master
      dest: /etc/sysconfig/atomic-openshift-master
      owner: root
      group: root
      mode: 0644
EOF

# Create Ansible Hosts File
echo $(date) " - Create Ansible Hosts file"
echo "Master count :" $MASTERCOUNT
if [ $MASTERCOUNT -eq 1 ]
then
# Ansible Host file for Single Master Configuration
cat > /etc/ansible/hosts <<EOF
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
etcd
nodes
nfs
master0
new_nodes
glusterfs

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
ansible_ssh_user=$SUDOUSER
ansible_become=true
openshift_cloudprovider_kind=azure
osm_controller_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/origin/cloudprovider/azure.conf']}
osm_api_server_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/origin/cloudprovider/azure.conf']}
openshift_node_kubelet_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/origin/cloudprovider/azure.conf'], 'enable-controller-attach-detach': ['true']}
openshift_install_examples=true
deployment_type=openshift-enterprise
docker_udev_workaround=true
openshift_use_dnsmasq=true
openshift_master_api_port=443
openshift_master_console_port=443
openshift_hosted_router_replicas=1
openshift_hosted_registry_replicas=1
openshift_master_cluster_method=native
openshift_node_local_quota_per_fsgroup=512Mi

openshift_disable_check=docker_image_availability
oreg_url_master=registry.access.redhat.com/openshift3/ose-${component}:${version}
oreg_url_node=registry.access.redhat.com/openshift3/ose-${component}:${version}
openshift_examples_modify_imagestreams=true
oreg_url=registry.access.redhat.com/openshift3/ose-${component}:${version}

# Do not uninstall service catalog until post installation. Needs storage class object
openshift_enable_service_catalog=false

# Setup azure blob registry storage
openshift_hosted_registry_storage_kind=object
openshift_hosted_registry_storage_provider=azure_blob
openshift_hosted_registry_storage_azure_blob_accountname=openshiftregistry
openshift_hosted_registry_storage_azure_blob_accountkey=$ACCOUNTKEY_REGISTRY
openshift_hosted_registry_storage_azure_blob_container=registry
openshift_hosted_registry_storage_azure_blob_realm=core.windows.net

openshift_master_default_subdomain=$ROUTING
openshift_override_hostname_check=true
osm_use_cockpit=true
os_sdn_network_plugin_name='redhat/openshift-ovs-multitenant'
# disable checks
openshift_disable_check=memory_availability,disk_availability,docker_storage,docker_storage_driver,package_version,docker_image_availability
# osm_controller_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/azure/azure.conf']}
# osm_api_server_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/azure/azure.conf']}
# openshift_node_kubelet_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/azure/azure.conf'], 'enable-controller-attach-detach': ['true']}
openshift_master_access_token_max_seconds=2419200
# openshift_cloudprovider_kind=azure

# apply updated node defaults
openshift_node_kubelet_args={'pods-per-core': ['10'], 'max-pods': ['250'], 'image-gc-high-threshold': ['90'], 'image-gc-low-threshold': ['80']}

openshift_master_cluster_hostname=$MASTERPUBLICIPHOSTNAME
openshift_master_cluster_public_hostname=$MASTERPUBLICIPHOSTNAME
#openshift_master_cluster_public_vip=$MASTERPUBLICIPADDRESS

# Enable HTPasswdPasswordIdentityProvider
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

# Setup metrics
openshift_metrics_install_metrics=false
openshift_metrics_hawkular_hostname=hawkular-metrics.$ROUTING
openshift_metrics_install_hawkular_agent=true
openshift_master_metrics_public_url=https://hawkular-metrics.$ROUTING/hawkular/metrics


# Setup logging
openshift_logging_install_logging=false
openshift_logging_kibana_hostname=kibana.$ROUTING
openshift_master_logging_public_url=https://kibana.$ROUTING
openshift_logging_master_public_url=https://$MASTERPUBLICIPHOSTNAME:443

# Setup storage for etcd2, for the new Service Broker

openshift_template_service_broker_namespaces=['openshift']
openshift_enable_service_catalog=false
ansible_service_broker_install=false
template_service_broker_install=false
openshift_service_catalog_image_version=latest
ansible_service_broker_image_prefix=registry.access.redhat.com/openshift3/ose-
ansible_service_broker_registry_url="registry.access.redhat.com"
openshift_service_catalog_image_prefix=registry.access.redhat.com/openshift3/ose-
ansible_service_broker_local_registry_whitelist=['.*-apb$']
template_service_broker_selector={"region":"infra"}

# ** Prometheus **
openshift_hosted_prometheus_deploy=false
openshift_prometheus_namespace=openshift-metrics
openshift_prometheus_node_selector={"region":"infra"}

# host group for masters
[masters]
$MASTER-0

[master0]
$MASTER-0

[etcd]
$MASTER-0

[nfs]
$MASTER-0

# host group for nodes
[nodes]
$MASTER-0 openshift_node_labels="{'region': 'master', 'zone': 'default'}" openshift_hostname=$MASTER-0
EOF

# Loop to add Infra Nodes

for (( c=0; c<$INFRACOUNT; c++ ))
do
  echo "$INFRA-$c openshift_node_labels=\"{'region': 'infra', 'zone': 'default'}\" openshift_hostname=$INFRA-$c" >> /etc/ansible/hosts
done

# Loop to add Nodes

for (( c=0; c<$NODECOUNT; c++ ))
do
  echo "$NODE-$c openshift_node_labels=\"{'region': 'app', 'zone': 'default'}\" openshift_hostname=$NODE-$c" >> /etc/ansible/hosts
done

# Loop to add CNS Nodes

for (( c=0; c<$CNSCOUNT; c++ ))
do
  echo "$CNS-$c openshift_schedulable=True  openshift_hostname=$CNS-$c" >> /etc/ansible/hosts
done


# glusterfs
echo "[glusterfs]" >>/etc/ansible/hosts
for (( c=0; c<$CNSCOUNT; c++ ))
do
  echo "$CNS-$c glusterfs_devices='[ \"/dev/sde\", \"/dev/sdd\", \"/dev/sdf\" ]' " >> /etc/ansible/hosts
done

# Create new_nodes group

cat >> /etc/ansible/hosts <<EOF
# host group for adding new nodes
[new_nodes]
EOF

else

cat > /etc/ansible/hosts <<EOF
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes
etcd
nfs
new_nodes
glusterfs
master0

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
ansible_ssh_user=$SUDOUSER
openshift_install_examples=true
deployment_type=openshift-enterprise
docker_udev_workaround=true
openshift_use_dnsmasq=true
openshift_master_default_subdomain=$ROUTING
openshift_override_hostname_check=true
osm_use_cockpit=true

ansible_become=true
openshift_cloudprovider_kind=azure
osm_controller_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/origin/cloudprovider/azure.conf']}
osm_api_server_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/origin/cloudprovider/azure.conf']}
openshift_node_kubelet_args={'cloud-provider': ['azure'], 'cloud-config': ['/etc/origin/cloudprovider/azure.conf'], 'enable-controller-attach-detach': ['true']}

openshift_master_access_token_max_seconds=2419200

# enable ntp on masters to ensure proper failover
openshift_clock_enabled=true

os_sdn_network_plugin_name='redhat/openshift-ovs-multitenant'
# disable checks
openshift_disable_check=memory_availability,disk_availability,docker_storage,docker_storage_driver,package_version,docker_image_availability


# apply updated node defaults
openshift_node_kubelet_args={'pods-per-core': ['10'], 'max-pods': ['250'], 'image-gc-high-threshold': ['90'], 'image-gc-low-threshold': ['80']}


openshift_master_cluster_method=native
openshift_master_cluster_hostname=$BASTION
openshift_master_cluster_public_hostname=$MASTERPUBLICIPHOSTNAME
#openshift_master_cluster_public_vip=$MASTERPUBLICIPADDRESS

# Enable HTPasswdPasswordIdentityProvider
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

openshift_master_api_port=443
openshift_master_console_port=443
openshift_hosted_router_replicas=3
openshift_hosted_registry_replicas=1
openshift_master_cluster_method=native
openshift_node_local_quota_per_fsgroup=512Mi

oreg_url_master=registry.access.redhat.com/openshift3/ose-${component}:${version}
oreg_url_node=registry.access.redhat.com/openshift3/ose-${component}:${version}
openshift_examples_modify_imagestreams=true
oreg_url=registry.access.redhat.com/openshift3/ose-${component}:${version}
# Do not uninstall service catalog until post installation. Needs storage class object
openshift_enable_service_catalog=false

# Setup azure blob registry storage
openshift_hosted_registry_storage_kind=object
openshift_hosted_registry_storage_provider=azure_blob
openshift_hosted_registry_storage_azure_blob_accountname=openshiftregistry
openshift_hosted_registry_storage_azure_blob_accountkey=$ACCOUNTKEY_REGISTRY
openshift_hosted_registry_storage_azure_blob_container=registry
openshift_hosted_registry_storage_azure_blob_realm=core.windows.net


openshift_metrics_install_metrics=false
openshift_metrics_hawkular_hostname=hawkular-metrics.$ROUTING
openshift_metrics_install_hawkular_agent=true
openshift_master_metrics_public_url=https://hawkular-metrics.$ROUTING/hawkular/metrics

# Setup logging
openshift_logging_install_logging=false
openshift_logging_kibana_hostname=kibana.$ROUTING
openshift_master_logging_public_url=https://kibana.$ROUTING
openshift_logging_master_public_url=https://$MASTERPUBLICIPHOSTNAME:443


# Setup storage for etcd2, for the new Service Broker
ansible_service_broker_local_registry_whitelist=['.*-apb$']
openshift_template_service_broker_namespaces=['openshift']
openshift_enable_service_catalog=false
ansible_service_broker_install=false
template_service_broker_install=false
openshift_service_catalog_image_version=latest
ansible_service_broker_image_prefix=registry.access.redhat.com/openshift3/ose-
ansible_service_broker_registry_url="registry.access.redhat.com"
openshift_service_catalog_image_prefix=registry.access.redhat.com/openshift3/ose-
template_service_broker_selector={"region":"infra"}

# ** Prometheus **
openshift_hosted_prometheus_deploy=false
openshift_prometheus_namespace=openshift-metrics
openshift_prometheus_node_selector={"region":"infra"}

# host group for masters
[masters]
$MASTER-[0:${MASTERLOOP}]
# host group for etcd
[etcd]
$MASTER-[0:${MASTERLOOP}]
[master0]
$MASTER-0
[nfs]
$MASTER-0

# host group for nodes
[nodes]
EOF

# Loop to add Masters

for (( c=0; c<$MASTERCOUNT; c++ ))
do
  echo "$MASTER-$c openshift_node_labels=\"{'region': 'master', 'zone': 'default'}\" openshift_hostname=$MASTER-$c" >> /etc/ansible/hosts
done

# Loop to add Infra Nodes

for (( c=0; c<$INFRACOUNT; c++ ))
do
  echo "$INFRA-$c openshift_node_labels=\"{'region': 'infra', 'zone': 'default'}\" openshift_hostname=$INFRA-$c" >> /etc/ansible/hosts
done

# Loop to add Nodes

for (( c=0; c<$NODECOUNT; c++ ))
do
  echo "$NODE-$c openshift_node_labels=\"{'region': 'app', 'zone': 'default'}\" openshift_hostname=$NODE-$c" >> /etc/ansible/hosts
done

# Loop to add CNS Nodes

for (( c=0; c<$CNSCOUNT; c++ ))
do
  echo "$CNS-$c openshift_schedulable=True  openshift_hostname=$CNS-$c" >> /etc/ansible/hosts
done

# glusterfs
echo "[glusterfs]" >>/etc/ansible/hosts
for (( c=0; c<$CNSCOUNT; c++ ))
do
  echo "$CNS-$c glusterfs_devices='[ \"/dev/sde\", \"/dev/sdd\", \"/dev/sdf\" ]' " >> /etc/ansible/hosts
done

# Create new_nodes group

cat >> /etc/ansible/hosts <<EOF
# host group for adding new nodes
[new_nodes]
EOF

fi

#echo "preinstall.yml playbook"
# Create correct hosts file on all servers
#runuser -l $SUDOUSER -c "ansible-playbook ~/preinstall.yml"
# add

# EmptyDir Storage (section 2.11.7)
echo $(date) " - EmptyDir Storage (section 2.11.7)"
runuser -l $SUDOUSER -c "ansible nodes -b -m filesystem -a \"fstype=xfs dev=/dev/sdc\""
runuser -l $SUDOUSER -c "ansible nodes -b -m file -a \"path=/var/lib/origin/openshift.local.volumes state=directory mode=0755\""
runuser -l $SUDOUSER -c "ansible nodes -b -m mount -a \"path=/var/lib/origin/openshift.local.volumes src=/dev/sdc state=present fstype=xfs opts=gquota\""
runuser -l $SUDOUSER -c "ansible nodes -b -m shell -a \"restorecon -R /var/lib/origin/openshift.local.volumes\""
runuser -l $SUDOUSER -c "ansible nodes -b -m mount -a \"path=/var/lib/origin/openshift.local.volumes src=/dev/sdc state=mounted fstype=xfs opts=gquota\""

# etcd storage
echo $(date) " - etcd Storage"
runuser -l $SUDOUSER -c "ansible masters -b -m filesystem -a \"fstype=xfs dev=/dev/sde\""
runuser -l $SUDOUSER -c "ansible masters -b -m file -a \"path=/var/lib/etcd state=directory mode=0755\""
runuser -l $SUDOUSER -c "ansible masters -b -m mount -a \"path=/var/lib/etcd src=/dev/sde state=present  fstype=xfs\""
runuser -l $SUDOUSER -c "ansible masters -b -m shell -a \"restorecon -R  /var/lib/etcd\""
runuser -l $SUDOUSER -c "ansible masters -b -m mount -a \"path=/var/lib/etcd  src=/dev/sde state=mounted fstype=xfs\""

# Container Storage
echo $(date) " Container Storage"
runuser -l $SUDOUSER -c "ansible-playbook -e 'container_runtime_docker_storage_setup_device=/dev/sdd'  -e 'container_runtime_docker_storage_type=overlay2' /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml"


# Initiating installation of OpenShift Container Platform using Ansible Playbook
echo $(date) " - Installing OpenShift Container Platform via Ansible Playbook"

runuser -l $SUDOUSER -c "ansible-playbook  /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml"

echo $(date) " - Modifying sudoers"

sed -i -e "s/Defaults    requiretty/# Defaults    requiretty/" /etc/sudoers
sed -i -e '/Defaults    env_keep += "LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"/aDefaults    env_keep += "PATH"' /etc/sudoers

# Deploying Registry
echo $(date) "- Registry deployed to infra node"

# Deploying Router
echo $(date) "- Router deployed to infra nodes"

echo $(date) "- Re-enabling requiretty"

sed -i -e "s/# Defaults    requiretty/Defaults    requiretty/" /etc/sudoers

# Adding user to OpenShift authentication file
echo $(date) "- Adding OpenShift user"

runuser -l $SUDOUSER -c "ansible-playbook ~/postinstall.yml"

# Assigning cluster admin rights to OpenShift user
echo $(date) "- Assigning cluster admin rights to user"

runuser -l $SUDOUSER -c "ansible-playbook ~/postinstall2.yml"

# Setting password for Cockpit
echo $(date) "- Assigning password for root, which is used to login to Cockpit"

runuser -l $SUDOUSER -c "ansible-playbook ~/postinstall3.yml"

# Unset of OPENSHIFT_DEFAULT_REGISTRY. Just the easiest way out.

cat > /tmp/atomic-openshift-master <<EOF
OPTIONS=--loglevel=2
CONFIG_FILE=/etc/origin/master/master-config.yaml
#OPENSHIFT_DEFAULT_REGISTRY=docker-registry.default.svc:5000


# Proxy configuration
# See https://docs.openshift.com/enterprise/latest/install_config/install/advanced_install.html#configuring-global-proxy
# Origin uses standard HTTP_PROXY environment variables. Be sure to set
# NO_PROXY for your master
#NO_PROXY=master.example.com
#HTTP_PROXY=http://USER:PASSWORD@IPADDR:PORT
#HTTPS_PROXY=https://USER:PASSWORD@IPADDR:PORT
EOF

chmod a+r /tmp/atomic-openshift-master

runuser -l $SUDOUSER -c "ansible-playbook ~/postinstall4.yml"

# OPENSHIFT_DEFAULT_REGISTRY UNSET MAGIC
if [ $MASTERCOUNT -ne 1 ]
then
	for item in $OCP-master-0 $OCP-master-1 $OCP-master-2; do
		runuser -l $SUDOUSER -c "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $item 'sudo sed -i \"s/OPENSHIFT_DEFAULT_REGISTRY/#OPENSHIFT_DEFAULT_REGISTRY/g\" /etc/sysconfig/atomic-openshift-master-api'"
		runuser -l $SUDOUSER -c "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $item 'sudo sed -i \"s/OPENSHIFT_DEFAULT_REGISTRY/#OPENSHIFT_DEFAULT_REGISTRY/g\" /etc/sysconfig/atomic-openshift-master-controllers'"
		runuser -l $SUDOUSER -c "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $item 'sudo systemctl restart atomic-openshift-master-api'"
		runuser -l $SUDOUSER -c "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $item 'sudo systemctl restart atomic-openshift-master-controllers'"
	done
else
	runuser -l $SUDOUSER -c "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $OCP-master-0 'sudo sed -i \"s/OPENSHIFT_DEFAULT_REGISTRY/#OPENSHIFT_DEFAULT_REGISTRY/g\" /etc/sysconfig/atomic-openshift-master-api'"
	runuser -l $SUDOUSER -c "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $OCP-master-0 'sudo sed -i \"s/OPENSHIFT_DEFAULT_REGISTRY/#OPENSHIFT_DEFAULT_REGISTRY/g\" /etc/sysconfig/atomic-openshift-master-controllers'"
	runuser -l $SUDOUSER -c "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $OCP-master-0 'sudo systemctl restart atomic-openshift-master-api'"
	runuser -l $SUDOUSER -c "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $OCP-master-0 'sudo systemctl restart atomic-openshift-master-controllers'"	
fi

# Execute setup-azure-master and setup-azure-node playbooks to configure Azure Cloud Provider
echo $(date) "- Configuring OpenShift Cloud Provider to be Azure"

runuser -l $SUDOUSER -c "ansible-playbook ~/setup-azure-master.yml"
runuser -l $SUDOUSER -c "ansible-playbook ~/setup-azure-node-master.yml"
runuser -l $SUDOUSER -c "ansible-playbook ~/setup-azure-node.yml"
# runuser -l $SUDOUSER -c "ansible-playbook ~/deletestucknodes.yml"
echo $(date) " - Script complete"

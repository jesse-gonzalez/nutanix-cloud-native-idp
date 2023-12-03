#!/bin/bash
set -e
set -o pipefail

source ~/.bashrc

echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

# echo "WORKAROUND: Checking if Karbon Cluster Management settings have been configured already"

ENABLE_ADVANCED_KARBON_MGMT=@@{enable_advanced_karbon_management}@@

## as interim fix - checking if karbon ui config exists and karbon_management is set to true. if so move ui config, update core config and restart services
if [[ "${ENABLE_ADVANCED_KARBON_MGMT}" == "true" ]]
then
  echo "karbon_ui_config.json already exists, will override as workaround to handling pre-existing management clusters that were deleted"
  #sshpass -p '@@{Nutanix Password.secret}@@' ssh nutanix@@@{pc_instance_ip}@@ -C "sudo mv /home/docker/karbon_ui/karbon_ui_config.json /home/docker/karbon_ui/karbon_ui_config-bckup.json"
  sshpass -p '@@{Nutanix Password.secret}@@' ssh nutanix@@@{pc_instance_ip}@@ -C "sudo cp /home/docker/karbon_core/karbon_core_config.json /home/docker/karbon_core/karbon_core_config-bkup.json"
  sshpass -p '@@{Nutanix Password.secret}@@' ssh nutanix@@@{pc_instance_ip}@@ -C "sudo sed -i 's/KARBON_MGMT_IP=.*/KARBON_MGMT_IP=\",/g' /home/docker/karbon_core/karbon_core_config.json"
  sshpass -p '@@{Nutanix Password.secret}@@' ssh nutanix@@@{pc_instance_ip}@@ -C "export PATH=$PATH:/usr/local/nutanix/cluster/bin/ ; genesis stop karbon_core karbon_ui && cluster start"
  sleep 60
fi

echo "Create Karbon K8s cluster"
karbonctl cluster create --file-path karbon_testing.json
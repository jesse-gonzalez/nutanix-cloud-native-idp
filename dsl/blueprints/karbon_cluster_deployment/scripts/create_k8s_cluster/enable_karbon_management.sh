#!/bin/bash
set -e
set -o pipefail

ENABLE_ADVANCED_KARBON_MGMT=@@{enable_advanced_karbon_management}@@

echo $ENABLE_ADVANCED_KARBON_MGMT

echo "Login karbonctl"
sshpass -p '@@{Nutanix Password.secret}@@' ssh nutanix@@@{pc_instance_ip}@@ -C "/home/nutanix/karbon/karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@"

## Enable NKE Management if set to true and Karbon version at 2.5
if [[ "${ENABLE_ADVANCED_KARBON_MGMT}" == "true" ]]
then
  echo "Enabling Karbon Advanced Management Cluster"
  sshpass -p '@@{Nutanix Password.secret}@@' ssh nutanix@@@{pc_instance_ip}@@ -C "export PATH=$PATH:/usr/local/nutanix/cluster/bin/ ; /home/nutanix/karbon/karbonctl karbon-management enable --cluster-name @@{k8s_cluster_name}@@"
  sshpass -p '@@{Nutanix Password.secret}@@' ssh nutanix@@@{pc_instance_ip}@@ -C "export PATH=$PATH:/usr/local/nutanix/cluster/bin/ ; /home/nutanix/karbon/karbonctl karbon-agent enable --cluster-name @@{k8s_cluster_name}@@ --mgmt-name @@{k8s_cluster_name}@@"
fi

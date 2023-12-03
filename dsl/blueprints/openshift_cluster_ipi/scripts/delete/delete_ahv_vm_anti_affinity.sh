#!/bin/bash
set -e
set -o pipefail

NTNX_PE_IP=@@{prism_element_external_ip}@@
NTNX_PE_PASS=@@{Prism Element User.secret}@@

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## get vm list from kubectl
CONTROL_PLANE_LIST=$(kubectl get nodes -l node-role.kubernetes.io/master= -o name | cut -d '/' -f2 | xargs | tr " " ",")
INFRA_NODE_LIST=$(kubectl get nodes -l node-role.kubernetes.io/infra= -o name | cut -d '/' -f2 | xargs | tr " " ",")

## clear out vm-vm anti-affinity groups for control plane nodes
sshpass -p $NTNX_PE_PASS ssh nutanix@$NTNX_PE_IP -C "export PATH=$PATH:/usr/local/nutanix/bin ; \
  acli vm_group.remove_vms controlplane-$OCP_CLUSTER_NAME vm_list=$CONTROL_PLANE_LIST; \
  acli vm_group.antiaffinity_unset controlplane-$OCP_CLUSTER_NAME; \
  acli vm_group.delete controlplane-$OCP_CLUSTER_NAME;"

## clear out vm-vm anti-affinity groups for infra nodes
sshpass -p $NTNX_PE_PASS ssh nutanix@$NTNX_PE_IP -C "export PATH=$PATH:/usr/local/nutanix/bin ; \
  acli vm_group.remove_vms infra-$OCP_CLUSTER_NAME vm_list=$INFRA_NODE_LIST; \
  acli vm_group.antiaffinity_unset infra-$OCP_CLUSTER_NAME; \
  acli vm_group.delete infra-$OCP_CLUSTER_NAME;"


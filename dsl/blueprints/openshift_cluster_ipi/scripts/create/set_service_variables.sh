#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## currently only setting kubeadmin pass, but other variables can be set
KUBEADMIN_PASS=$(cat $OCP_BUILD_CACHE_BASE/auth/kubeadmin-password)

echo "kube_admin_password=${KUBEADMIN_PASS}"

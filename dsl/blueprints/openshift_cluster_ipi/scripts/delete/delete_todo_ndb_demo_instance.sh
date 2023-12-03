#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

NAMESPACE=todo
POSTGRESQL_INSTANCE_NAME='todo-db'

## configure namespace where ndb operator - database custom resource will live
kubectl delete database ${POSTGRESQL_INSTANCE_NAME} -n $NAMESPACE --wait=false


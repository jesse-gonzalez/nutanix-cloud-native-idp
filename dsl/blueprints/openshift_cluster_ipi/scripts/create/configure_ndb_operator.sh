#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

helm repo add nutanix https://nutanix.github.io/helm/
helm upgrade --install ndb-operator nutanix/ndb-operator -n ndb-operator \
  --create-namespace \
  --wait \
  --wait-for-jobs

while [[ -z $(kubectl get deployment -l control-plane=ndb-operator-controller-manager -n ndb-operator 2>/dev/null) ]]; do
  echo "Waiting for ndb-operator-controller-manager deployment to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=5m -n ndb-operator $(kubectl get deployment -l control-plane=ndb-operator-controller-manager -n ndb-operator -o name)
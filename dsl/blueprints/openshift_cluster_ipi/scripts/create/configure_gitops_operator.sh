#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

OPERATOR_NS=openshift-operators
OPERATOR_NAME=openshift-gitops-operator
OPERATOR_CHANNEL=latest

## Only run on OCP hub cluster
ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "true" ]]
then

## get options: kubectl describe packagemanifests openshift-gitops -n openshift-marketplace
## kubectl install operator from openshift-marketplace
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $OPERATOR_NAME
  namespace: $OPERATOR_NS
spec:
  config:
    tolerations:
    - key: "node-role.kubernetes.io/infra"
      operator: "Exists"
      value: ""
      effect: "NoSchedule"
  channel: $OPERATOR_CHANNEL
  name: $OPERATOR_NAME
  installPlanApproval: Automatic
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

while [[ -z $(kubectl get deployment gitops-operator-controller-manager -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for gitops-operator-controller-manager deployments to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=15m -n $OPERATOR_NS $(kubectl get deployment gitops-operator-controller-manager -n $OPERATOR_NS -o name)

## waiting for openshift-gitops namespace and pods to be available
while [[ -z $(kubectl get deployment -l app.kubernetes.io/managed-by=openshift-gitops -n openshift-gitops 2>/dev/null) ]]; do
  echo "Waiting for gitops-operator-controller-manager deployments to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=15m deployment -l app.kubernetes.io/managed-by=openshift-gitops -n openshift-gitops

fi
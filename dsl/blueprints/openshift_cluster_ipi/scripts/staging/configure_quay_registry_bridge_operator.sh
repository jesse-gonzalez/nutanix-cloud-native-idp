#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

OPERATOR_NS=openshift-operators
OPERATOR_NAME=quay-bridge-operator
OPERATOR_CHANNEL=stable-3.8

ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "false" ]]
then

## kubectl create operator namespace
## kubectl create ns $OPERATOR_NS --dry-run=client -o yaml | kubectl apply -f -

## kubectl create operatorgroup
# cat <<EOF | kubectl apply -f -
# apiVersion: operators.coreos.com/v1
# kind: OperatorGroup
# metadata:
#   name: $OPERATOR_NAME-opgroup
#   namespace: $OPERATOR_NS
# spec:
#   targetNamespaces:
#   - $OPERATOR_NS
# EOF

# kubectl get operatorgroup -n $OPERATOR_NS

## get options: kubectl get packagemanifests -n openshift-marketplace  ansible-automation-platform-operator
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

while [[ -z $(kubectl get deployment -l olm.owner.namespace=$OPERATOR_NS -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for Quay Registry Operator controller deployments to be created..."
  sleep 30
done

kubectl wait --for=condition=available --timeout=10m -n $OPERATOR_NS $(kubectl get deployment -n $OPERATOR_NS -o name)

fi

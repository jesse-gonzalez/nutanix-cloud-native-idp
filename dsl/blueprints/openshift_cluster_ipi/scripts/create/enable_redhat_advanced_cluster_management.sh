#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

OPERATOR_NS=open-cluster-management
OPERATOR_NAME=advanced-cluster-management
OPERATOR_CHANNEL=release-2.8

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "true" ]]
then

## Enable ACM Operator via OperatorHub
echo "Enabling RedHat Advanced Cluster Management"

## kubectl create operator namespace
kubectl create ns $OPERATOR_NS --dry-run=client -o yaml | kubectl apply -f -

## kubectl create operatorgroup. using open-cluster-management-operator-group to align with validated pattern
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: open-cluster-management-operator-group
  namespace: $OPERATOR_NS
spec:
  targetNamespaces:
  - $OPERATOR_NS
EOF

kubectl get operatorgroup -n $OPERATOR_NS

## get options: kubectl describe packagemanifests redhat-oadp-operator -n openshift-marketplace
## kubectl install operator from openshift-marketplace
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $OPERATOR_NAME
  namespace: $OPERATOR_NS
spec:
  config:
    nodeSelector:
      node-role.kubernetes.io/infra: ""
    tolerations:
    - key: node-role.kubernetes.io/infra
      effect: NoSchedule
      operator: Exists
  channel: $OPERATOR_CHANNEL
  name: $OPERATOR_NAME
  installPlanApproval: Automatic
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

while [[ -z $(kubectl get deployment -l olm.owner.namespace=$OPERATOR_NS -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for operator-controller-manager deployment to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=5m -n $OPERATOR_NS $(kubectl get deployment -n $OPERATOR_NS -o name)
sleep 10s ## to handle api server disconnect failures, needs further investigation

#### Configuring Custom Resources
## Configure MultiClusterHub CR

cat <<EOF | kubectl apply -f -
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  name: multiclusterhub
  namespace: $OPERATOR_NS
spec:
  tolerations:
  - key: node-role.kubernetes.io/infra
    effect: NoSchedule
    operator: Exists
EOF

## Ensure all the pods are Running in the namespace “open-cluster-management”
while [[ -z $(kubectl get deployment -l olm.owner.namespace=$OPERATOR_NS -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for Advanced Cluster Manager deployments to be created..."
  sleep 30
done

kubectl wait --for=condition=available --timeout=20m -n $OPERATOR_NS $(kubectl get deployment -n $OPERATOR_NS -o name)

## setting default label to clusterGroup=hub. Needed for validated operator pattern.
while [[ -z $(kubectl get managedcluster local-cluster -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for Advanced Cluster Manager Managed Cluster to be available..."
  sleep 30
done

kubectl label managedcluster local-cluster clusterGroup=hub -n $OPERATOR_NS --overwrite

## Validate Connectivity
## It creates a route in the “open-cluster-management” namespace. https://multicloud-console.apps.$OCP_CLUSTER_NAME.$DOMAIN/multicloud/home/overview 
kubectl get route -n $OPERATOR_NS

fi

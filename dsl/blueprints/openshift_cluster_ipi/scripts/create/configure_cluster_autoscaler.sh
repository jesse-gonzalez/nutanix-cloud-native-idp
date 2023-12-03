#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

# OCP_CLUSTER_NAME=kalm-main-20-4-ocp

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

cat <<EOF | kubectl apply -f -
apiVersion: "autoscaling.openshift.io/v1"
kind: "ClusterAutoscaler"
metadata:
  name: "default"
spec:
  resourceLimits:
    maxNodesTotal: 20
  scaleDown:
    enabled: true
    delayAfterAdd: 10s
    delayAfterDelete: 10s
    delayAfterFailure: 10s
EOF

kubectl get clusterautoscaler default

kubectl describe clusterautoscaler default

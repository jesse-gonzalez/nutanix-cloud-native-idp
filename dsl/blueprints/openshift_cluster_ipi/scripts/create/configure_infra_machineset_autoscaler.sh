#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

# OCP_CLUSTER_NAME=kalm-main-20-4-ocp

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

MACHINE_SET_NAME=$(kubectl get machineset -n openshift-machine-api -o name | grep infra | cut -d/ -f2)

MIN_REPLICAS=@@{infra_machineset_count}@@
MAX_REPLICAS=5

cat <<EOF | kubectl apply -f -
apiVersion: autoscaling.openshift.io/v1beta1
kind: MachineAutoscaler
metadata:
  name: $MACHINE_SET_NAME
  namespace: openshift-machine-api
spec:
  minReplicas: $MIN_REPLICAS
  maxReplicas: $MAX_REPLICAS
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: $MACHINE_SET_NAME
EOF

kubectl get machineautoscaler $MACHINE_SET_NAME -n openshift-machine-api

kubectl describe machineautoscaler $MACHINE_SET_NAME -n openshift-machine-api

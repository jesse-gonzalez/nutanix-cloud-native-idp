#!/bin/bash
set -e
set -o pipefail

echo "Set KUBECONFIG"
export KUBECONFIG=~/@@{k8s_cluster_name}@@.cfg

echo "Install Kubernetes Dashboard"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml

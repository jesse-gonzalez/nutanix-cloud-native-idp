#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

## run openshift-install create cluster
openshift-install create cluster --dir $OCP_BUILD_CACHE_BASE --log-level debug

## copy kubeconfig file to .kube dir
cp $OCP_BUILD_CACHE_BASE/auth/kubeconfig $HOME/.kube/$OCP_CLUSTER_NAME.cfg

# configure local kubeconfig context
kubectl config --kubeconfig $HOME/.kube/$OCP_CLUSTER_NAME.cfg rename-context admin $OCP_CLUSTER_NAME
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

# quick validation
kubectl cluster-info
kubectl get nodes -o wide

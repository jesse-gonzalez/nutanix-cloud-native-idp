#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## https://cloud.redhat.com/blog/ocp-disaster-recovery-part-1-how-to-create-automated-etcd-backup-in-openshift-4.x

## create etcd backup
TIMESTAMP=$(date +%F-%H%M%S)
kubectl create job etcd-backup-$TIMESTAMP --from=cronjob/openshift-backup -n ocp-etcd-backup --dry-run=client -o yaml | kubectl apply -f -

## monitor job completion
kubectl -n ocp-etcd-backup wait --for=condition=complete --timeout=5m job/etcd-backup-$TIMESTAMP

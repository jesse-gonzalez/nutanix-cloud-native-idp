#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## Only run on OCP hub cluster
ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "true" ]]
then

## kubectl argocd namespace
kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -

## create tls cert for argocd instance
export CERTDIR=.local/$OCP_CLUSTER_NAME/certs

kubectl create secret tls argocd-tls --cert=$CERTDIR/fullchain.pem --key=$CERTDIR/key.pem -n argocd --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: argocd
  namespace: argocd
spec:
  server:
    route:
      enabled: true
  tls:
    ca:
      secretName: argocd-tls
EOF

while [[ -z $(kubectl get deployment -l app.kubernetes.io/managed-by=argocd -n argocd 2>/dev/null) ]]; do
  echo "Waiting for argocd deployments to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=30m deployment -l app.kubernetes.io/managed-by=argocd -n argocd

fi
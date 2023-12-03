#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

export CERTDIR=.local/$OCP_CLUSTER_NAME/certs

## update ingress router with valid certs, generated from previous step
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

kubectl create secret tls router-certs --cert=$CERTDIR/fullchain.pem --key=$CERTDIR/key.pem -n openshift-ingress --dry-run=client -o yaml | kubectl apply -f -
kubectl patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'
sleep 60s ## to handle api server disconnect failures, needs further investigation

## wait for ingress controller to be completed with rolling update
while [[ -z $(kubectl get pod -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default 2>/dev/null) ]]; do
  echo "Waiting for ingress controller pods to be ready..."
  sleep 30
done

## 2 attempts to wait needed as this step seems to fail waiting for pod to terminating and properly startup
kubectl wait --for=jsonpath='{.status.phase}'=Running pod -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default --timeout 20m || kubectl rollout restart deploy router-default -n openshift-ingress

kubectl rollout status deploy router-default -n openshift-ingress

## validate
#kubectl get route -n openshift-console

##curl --silent --show-error --fail https://console-openshift-console.apps.$OCP_CLUSTER_NAME.$DOMAIN

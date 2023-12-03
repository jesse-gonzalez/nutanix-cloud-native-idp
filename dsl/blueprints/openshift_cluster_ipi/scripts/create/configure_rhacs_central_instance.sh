#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

export CERTDIR=.local/$OCP_CLUSTER_NAME/certs
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## https://www.redhat.com/sysadmin/kubernetes-RHACS-red-hat-advanced-cluster-security
## https://github.com/rhthsa/openshift-demo/blob/main/acs.md

## Only run on OCP hub cluster
ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "true" ]]
then

## kubectl create acs central cluster namespace
kubectl create ns stackrox --dry-run=client -o yaml | kubectl apply -f -

## get same certs configured for ingress router
kubectl create secret tls acs-central --cert=$CERTDIR/fullchain.pem --key=$CERTDIR/key.pem -n stackrox --dry-run=client -o yaml | kubectl apply -f -

## configure central service cluster instance
cat <<EOF | kubectl apply -f -
apiVersion: platform.stackrox.io/v1alpha1
kind: Central
metadata:
  name: stackrox-central-services
  namespace: stackrox
spec:
  central:
    defaultTLSSecret:
      name: acs-central
    exposure:
      loadBalancer:
        enabled: false
        port: 443
      nodePort:
        enabled: false
      route:
        enabled: true
    db:
      isEnabled: Default
      persistence:
        persistentVolumeClaim:
          claimName: central-db
    persistence:
      persistentVolumeClaim:
        claimName: stackrox-db
  egress:
    connectivityPolicy: Online
  scanner:
    analyzer:
      scaling:
        autoScaling: Enabled
        maxReplicas: 5
        minReplicas: 2
        replicas: 3
    scannerComponent: Enabled
EOF

while [[ -z $(kubectl get deployments -l app.kubernetes.io/instance=stackrox-central-services -n stackrox 2>/dev/null) ]]; do
  echo "Waiting for Stackrox Central Deployments to be created..."
  sleep 30
done

kubectl wait --for=condition=available --timeout=15m -n stackrox $(kubectl get deployment.apps/central -n stackrox -o name)
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=15m -n stackrox $(kubectl get deployment.apps/scanner -n stackrox -o name)
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=15m -n stackrox $(kubectl get deployment.apps/scanner-db -n stackrox -o name)
sleep 10s ## to handle api server disconnect failures, needs further investigation

## Validate Connectivity
kubectl get route.route.openshift.io/central -n stackrox

## Get central htpass
kubectl get secret central-htpasswd -o jsonpath='{.data.password}' -n stackrox | base64 -d

fi
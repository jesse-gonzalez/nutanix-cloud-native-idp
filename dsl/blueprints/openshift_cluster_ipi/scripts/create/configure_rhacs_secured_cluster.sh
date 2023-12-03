#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

#OCP_CLUSTER_NAME=kalm-main-12-1-ocp

OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

mkdir -p $OCP_BUILD_CACHE_BASE

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## https://www.redhat.com/sysadmin/kubernetes-RHACS-red-hat-advanced-cluster-security

## Only run on OCP hub cluster
ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "true" ]]
then

## get central cluster info
ROX_PASSWORD=$(kubectl get secret central-htpasswd -n stackrox -o jsonpath='{.data.password}' | base64 -d)
BASIC_AUTH_TOKEN=$(echo -n "admin:${ROX_PASSWORD}" | base64)

export ROX_CENTRAL_ADDRESS=$(kubectl get route central -n stackrox -o jsonpath='{.spec.host}'):443
export ROX_API_TOKEN=$(curl -sk -X POST --url https://$ROX_CENTRAL_ADDRESS/v1/apitokens/generate -H "Authorization: Basic $BASIC_AUTH_TOKEN" -H 'Content-Type: application/json' --data '{"name": "roxctl-api-token","role": "Admin"}' | jq -r '.token')

## Generate cluster init bundle
if [ ! -f $OCP_BUILD_CACHE_BASE/$OCP_CLUSTER_NAME-init-bundle.yaml ]; then
  roxctl --insecure-skip-tls-verify -e "$ROX_CENTRAL_ADDRESS" central init-bundles generate $OCP_CLUSTER_NAME --output $OCP_BUILD_CACHE_BASE/$OCP_CLUSTER_NAME-init-bundle.yaml
fi

## Create collectors via Helm, should be replaced with operator alone...
helm repo add rhacs https://mirror.openshift.com/pub/rhacs/charts/
helm repo update
helm upgrade --install -n stackrox stackrox-secured-cluster-services rhacs/secured-cluster-services \
-f $OCP_BUILD_CACHE_BASE/${OCP_CLUSTER_NAME}-init-bundle.yaml \
--set clusterName=${OCP_CLUSTER_NAME} \
--set imagePullSecrets.allowNone=true \
--wait \
--wait-for-jobs

## configure central service cluster instance
cat <<EOF | kubectl apply -f -
kind: SecuredCluster
apiVersion: platform.stackrox.io/v1alpha1
metadata:
  name: stackrox-secured-cluster-services
  namespace: stackrox
spec:
  clusterName: $OCP_CLUSTER_NAME
EOF

while [[ -z $(kubectl get deployment -l app.kubernetes.io/instance=stackrox-secured-cluster-services -n stackrox 2>/dev/null) ]]; do
  echo "Waiting for stackrox-secured-cluster-services deployments to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=15m -n stackrox $(kubectl get deployment -n stackrox -l app.kubernetes.io/instance=stackrox-secured-cluster-services -o name)

fi
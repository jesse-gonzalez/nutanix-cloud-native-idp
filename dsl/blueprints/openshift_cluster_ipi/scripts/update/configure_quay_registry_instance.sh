#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_HUB_CLUSTER_NAME=@@{ocp_hub_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

OBJECTS_ACCESS_KEY='@@{Objects S3 Access Key.username}@@'
OBJECTS_SECRET_KEY='@@{Objects S3 Access Key.secret}@@'
OBJECTS_STORE_DNS_FQDN='@@{objects_store_dns_fqdn}@@'

OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## Only run on OCP hub cluster
ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "true" ]]
then

## Configure Quay Registry

## Create Quay Config File
cat <<EOF | tee $OCP_BUILD_CACHE_BASE/quay-config.yaml
SERVER_HOSTNAME: quay.apps.$OCP_CLUSTER_NAME.$OCP_BASE_DOMAIN
FEATURE_USER_INITIALIZE: true
FEATURE_PROXY_CACHE: true
ALLOW_PULLS_WITHOUT_STRICT_LOGGING: false
AUTHENTICATION_TYPE: Database
DEFAULT_TAG_EXPIRATION: 2w
ENTERPRISE_LOGO_URL: /static/img/quay-horizontal-color.svg
FEATURE_BUILD_SUPPORT: false
FEATURE_DIRECT_LOGIN: true
FEATURE_MAILING: false
REGISTRY_TITLE: Quay
REGISTRY_TITLE_SHORT: Quay
SETUP_COMPLETE: true
TAG_EXPIRATION_OPTIONS:
- 2w
TEAM_RESYNC_STALE_TIME: 60m
TESTING: false
DISTRIBUTED_STORAGE_CONFIG:
  s3Storage:
    - S3Storage
    - host: $OBJECTS_STORE_DNS_FQDN
      s3_access_key: $OBJECTS_ACCESS_KEY
      s3_secret_key: $OBJECTS_SECRET_KEY
      s3_bucket: quay
      storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE:
    - s3Storage
EOF

## Create Project for Quay with toleration for Infrastructure Nodes
cat <<EOF | kubectl apply -f -
kind: Project
apiVersion: project.openshift.io/v1
metadata:
  name: quay-registry
  annotations:
    openshift.io/node-selector: 'node-role.kubernetes.io/infra='
    scheduler.alpha.kubernetes.io/defaultTolerations: >-
      [{"operator": "Exists", "effect": "NoSchedule", "key":
      "node-role.kubernetes.io/infra"}
      ]
EOF

## Get objects cacert
openssl s_client -showcerts -verify 5 -connect $OBJECTS_STORE_DNS_FQDN:443 -servername $OBJECTS_STORE_DNS_FQDN < /dev/null 2> /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; print}' > $OCP_BUILD_CACHE_BASE/objectca.crt
openssl x509 -in $OCP_BUILD_CACHE_BASE/objectca.crt -noout -text

## Create Secret with config.yaml (also add necessary certs like for Objects, should be fullchain....)
kubectl create -n quay-registry secret generic config-bundle-secret \
  --from-file config.yaml=$OCP_BUILD_CACHE_BASE/quay-config.yaml \
  --from-file=extra_ca_cert_my-custom-ssl.crt=$OCP_BUILD_CACHE_BASE/objectca.crt \
  --dry-run=client -o yaml | kubectl apply -f -

## validate secret was set correctly
kubectl get secret -n quay-registry config-bundle-secret -o jsonpath='{.data.config\.yaml}' | base64 -d

## configure custom resource instance of quayregistry
cat <<EOF | kubectl apply -f -
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: quay-registry
  namespace: quay-registry
spec:
  configBundleSecret: config-bundle-secret
EOF

while [[ -z $(kubectl get deployments -l quay-operator/quayregistry=quay-registry -n quay-registry 2>/dev/null) ]]; do
  echo "Waiting for Quay Registry Deployments to be created..."
  sleep 30
done

kubectl wait --for=condition=available --timeout=30m -n quay-registry $(kubectl get deployment.apps/quay-registry-quay-config-editor -n quay-registry -o name)
sleep 20s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=30m -n quay-registry $(kubectl get deployment.apps/quay-registry-quay-database -n quay-registry -o name)
sleep 20s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=30m -n quay-registry $(kubectl get deployment.apps/quay-registry-clair-postgres -n quay-registry -o name)
sleep 20s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=30m -n quay-registry $(kubectl get deployment.apps/quay-registry-quay-redis -n quay-registry -o name)
sleep 20s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=30m -n quay-registry $(kubectl get deployment.apps/quay-registry-clair-app -n quay-registry -o name) || kubectl rollout restart deployment.apps/quay-registry-clair-app -n quay-registry && kubectl rollout status deployment.apps/quay-registry-clair-app -n quay-registry
sleep 20s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=30m -n quay-registry $(kubectl get deployment.apps/quay-registry-quay-app -n quay-registry -o name) || kubectl rollout restart deployment.apps/quay-registry-quay-app -n quay-registry && kubectl rollout status deployment.apps/quay-registry-quay-app -n quay-registry
sleep 20s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=30m -n quay-registry $(kubectl get deployment.apps/quay-registry-quay-mirror -n quay-registry -o name) || kubectl rollout restart deployment.apps/quay-registry-quay-mirror -n quay-registry && kubectl rollout status deployment.apps/quay-registry-quay-mirror -n quay-registry
sleep 20s ## to handle api server disconnect failures, needs further investigation

## Validate Connectivity
kubectl get route.route.openshift.io/quay-registry-quay -n quay-registry

## https://access.redhat.com/documentation/en-us/red_hat_quay/3.8/html/deploy_red_hat_quay_on_openshift_with_the_quay_operator/operator-deploy
## Initialize Quay Admin with default pass from
curl -X POST -k  https://quay.apps.$OCP_HUB_CLUSTER_NAME.$OCP_BASE_DOMAIN/api/v1/user/initialize \
  --header 'Content-Type: application/json' \
  --data '{ "username": "quayadmin", "password":"default", "email": "admin@example.com", "access_token": true}'

echo -e "\nQuay Registry Console: https://$(kubectl get route quay-registry-quay -n quay-registry -o jsonpath='{.spec.host}')"
echo -e "\nQuay Password: "

fi
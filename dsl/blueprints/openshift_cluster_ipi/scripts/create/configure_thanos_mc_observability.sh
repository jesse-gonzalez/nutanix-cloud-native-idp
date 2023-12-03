#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

OBJECTS_ACCESS_KEY='@@{Objects S3 Access Key.username}@@'
OBJECTS_SECRET_KEY='@@{Objects S3 Access Key.secret}@@'
OBJECTS_STORE_ENDPOINT='@@{objects_store_dns_fqdn}@@'

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

DEFAULT_MONITORING_BUCKET='thanos'

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "true" ]]
then

## https://cloud.redhat.com/blog/leveraging-the-red-hat-advanced-cluster-management-observability-to-support-openshift-3-to-openshift-4-migration

## Create namespace - open-cluster-management-observability
kubectl create namespace open-cluster-management-observability --dry-run=client -o yaml | kubectl apply -f -

## Create a pull secret in the namespace “open-cluster-management-observability”.
DOCKER_CONFIG_JSON=`oc extract secret/pull-secret -n openshift-config --to=-`

kubectl create secret generic multiclusterhub-operator-pull-secret \
    -n open-cluster-management-observability \
    --from-literal=.dockerconfigjson="$DOCKER_CONFIG_JSON" \
    --type=kubernetes.io/dockerconfigjson --dry-run=client -o yaml | kubectl apply -f -

## Create a secret for Objects
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket: $DEFAULT_MONITORING_BUCKET
      endpoint: $OBJECTS_STORE_ENDPOINT
      insecure: true
      access_key: $OBJECTS_ACCESS_KEY
      secret_key: $OBJECTS_SECRET_KEY
EOF

kubectl create sa observability-thanos-store-shard -n open-cluster-management-observability --dry-run=client -o yaml | kubectl apply -f -

## Create the MultiClusterObservability CR
cat <<EOF | kubectl apply -f -
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
 name: observability
spec:
  enableDownsampling: true
  observabilityAddonSpec:
    enableMetrics: true
    interval: 300
  nodeSelector:
    node-role.kubernetes.io/infra:
  storageConfig:
    alertmanagerStorageSize: 1Gi
    compactStorageSize: 100Gi
    metricObjectStorage:
      key: thanos.yaml
      name: thanos-object-storage
    receiveStorageSize: 100Gi
    ruleStorageSize: 1Gi
    storageClass: nutanix-volume
    storeStorageSize: 10Gi
EOF

## Wait for all the deployments and statefulsets to be created be trying to wait in “open-cluster-management-observability”.
while [[ -z $(kubectl get deployment -l app.kubernetes.io/instance=observability -n open-cluster-management-observability 2>/dev/null) ]]; do
  echo "Waiting for multicluster observability deployments to be created..."
  sleep 15
done

while [[ -z $(kubectl get deployment -l observability.open-cluster-management.io/name=observability -n open-cluster-management-observability 2>/dev/null) ]]; do
  echo "Waiting for multicluster observability deployments to be created..."
  sleep 15
done

while [[ -z $(kubectl get sts -l observability.open-cluster-management.io/name=observability -n open-cluster-management-observability 2>/dev/null) ]]; do
  echo "Waiting for multicluster observability statefulsets to be created..."
  sleep 15
done


## Ensure all the pods are Running in the namespace “open-cluster-management”
kubectl wait --for=condition=available --timeout=60m deployment -l app.kubernetes.io/instance=observability -n open-cluster-management-observability
sleep 30s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=60m deployment -l observability.open-cluster-management.io/name=observability -n open-cluster-management-observability
sleep 30s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=60m deployment -l observability.open-cluster-management.io/name=observability -n open-cluster-management-observability
sleep 30s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=Ready --timeout=60m pods -l app.kubernetes.io/part-of=observatorium -n open-cluster-management-observability
sleep 30s ## to handle api server disconnect failures, needs further investigation

## Validate Access the Grafana URL through the route 
kubectl get route -n open-cluster-management-observability grafana

## echo https://grafana-open-cluster-management-observability.apps.$OCP_CLUSTER_NAME.$DOMAIN/

fi
#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

OBJECTS_ACCESS_KEY='@@{Objects S3 Access Key.username}@@'
OBJECTS_SECRET_KEY='@@{Objects S3 Access Key.secret}@@'
OBJECTS_STORE_DNS_FQDN='@@{objects_store_dns_fqdn}@@'

OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## https://portal.nutanix.com/page/documents/solutions/details?targetId=TN-2030-Red-Hat-OpenShift-on-Nutanix:openshift-image-registry.html

## Get objects cacert
openssl s_client -showcerts -verify 5 -connect $OBJECTS_STORE_DNS_FQDN:443 -servername $OBJECTS_STORE_DNS_FQDN < /dev/null 2> /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; print}' > $OCP_BUILD_CACHE_BASE/object-ca.pem
openssl x509 -in $OCP_BUILD_CACHE_BASE/object-ca.pem -noout -text

## Create a ConfigMap from the downloaded PEM file.
kubectl create configmap object-ca --from-file=ca-bundle.crt=$OCP_BUILD_CACHE_BASE/object-ca.pem -n openshift-config --dry-run=client -o yaml | kubectl apply -f -

## Assign the ConfigMap to the global proxy-settings.
kubectl patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"object-ca"}}}'

## Create a secret containing your bucket credentials.
kubectl create secret generic image-registry-private-configuration-user \
    --from-literal=REGISTRY_STORAGE_S3_ACCESSKEY=$OBJECTS_ACCESS_KEY \
    --from-literal=REGISTRY_STORAGE_S3_SECRETKEY=$OBJECTS_SECRET_KEY \
    --namespace openshift-image-registry --dry-run=client -o yaml | kubectl apply -f -

## Patch the image registry to use the bucket.
kubectl patch configs.imageregistry.operator.openshift.io/cluster \
    --type='json' \
    --patch='[{"op": "remove", "path": "/spec/storage" },{"op": "add", "path": "/spec/storage", "value":{"s3":{"bucket": "image-registry-bucket", "regionEndpoint": "https://'${OBJECTS_STORE_DNS_FQDN}'","encrypt": false,"region": "us-east-1"}}}]'

## Enable the image registry in OpenShift.
kubectl patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'

# cat <<EOF | kubectl apply -f -
# kind: PersistentVolumeClaim
# apiVersion: v1
# metadata:
#   name: image-registry-claim
#   namespace: openshift-image-registry
# spec:
#   accessModes:
#   - ReadWriteOnce
#   resources:
#     requests:
#       storage: 100Gi
#   storageClassName: nutanix-volume
# EOF

# # Patch OC Image Registry to use created PVC
# oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed","storage":{"pvc":{"claim":"image-registry-claim"}},"rolloutStrategy": "Recreate"}}'

#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

## set env variables
RELEASE_IMAGE=$(openshift-install version | awk '/release image/ {print $3}')
CCO_IMAGE=$(oc adm release info --image-for='cloud-credential-operator' $RELEASE_IMAGE)

## make cache dirs
mkdir -p $OCP_BUILD_CACHE_BASE
mkdir -p $OCP_BUILD_CACHE_BASE/creds

## configure ccoctl bin
oc image extract $CCO_IMAGE --file="/usr/local/bin" -a .local/$OCP_CLUSTER_NAME/pull-secret.json
chmod u+x /usr/local/bin/ccoctl
ccoctl --help

cat <<EOF | tee $OCP_BUILD_CACHE_BASE/creds/pc_credentials.yaml
credentials:
- type: basic_auth 
  data:
    prismCentral:
      username: @@{Prism Central User.username}@@
      password: @@{Prism Central User.secret}@@
EOF

# apiVersion: v1
# kind: Secret
# metadata:
#   name: nutanix-credentials
#   namespace: openshift-cloud-controller-manager
# type: Opaque
# data:
#   credentials: xxx

## make credrequests dir
oc adm release extract --credentials-requests --cloud=nutanix --to=$OCP_BUILD_CACHE_BASE/credrequests -a .local/$OCP_CLUSTER_NAME/pull-secret.json $RELEASE_IMAGE

ls $OCP_BUILD_CACHE_BASE/credrequests

ccoctl nutanix create-shared-secrets --credentials-requests-dir=$OCP_BUILD_CACHE_BASE/credrequests --output-dir=$OCP_BUILD_CACHE_BASE --credentials-source-filepath=$OCP_BUILD_CACHE_BASE/creds/pc_credentials.yaml

cat $OCP_BUILD_CACHE_BASE/manifests/openshift-machine-api-nutanix-credentials-credentials.yaml
#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## set pe cluster vars
NTNX_PE_IP=@@{prism_element_external_ip}@@
NTNX_PE_PORT=9440
NTNX_PE_USER=@@{Prism Element User.username}@@
NTNX_PE_PASS=@@{Prism Element User.secret}@@
NTNX_PE_STORAGE_CTR_NAME=@@{storage_container_name}@@
NTNX_CSI_DRIVER_NS='openshift-cluster-csi-drivers'

## create openshift-cluster-csi-drivers namespace/project
kubectl create ns openshift-cluster-csi-drivers --dry-run=client -o yaml | kubectl apply -f -

## kubectl create ntnx-secret needed for storageclass definitions
kubectl create secret generic ntnx-secret --namespace openshift-cluster-csi-drivers --from-literal key="$NTNX_PE_IP:$NTNX_PE_PORT:$NTNX_PE_USER:$NTNX_PE_PASS" --dry-run=client -o yaml | kubectl apply -f -

## kubectl create ntnx-csi-drivers-opgroup operatorgroup
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: nutanixcsioperator-opgroup
  namespace: openshift-cluster-csi-drivers
spec:
  targetNamespaces:
  - openshift-cluster-csi-drivers
EOF

## kubectl install nutanixcsi operator from openshift-marketplace
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nutanixcsioperator
  namespace: openshift-cluster-csi-drivers
spec:
  config:
    tolerations:
    - key: "node-role.kubernetes.io/infra"
      operator: "Exists"
      value: ""
      effect: "NoSchedule"
  channel: stable
  name: nutanixcsioperator
  installPlanApproval: Automatic
  source: certified-operators
  sourceNamespace: openshift-marketplace
EOF

while [[ -z $(kubectl get deployments nutanix-csi-operator-controller-manager -n openshift-cluster-csi-drivers 2>/dev/null) ]]; do
  echo "Waiting for nutanix-csi-operator-controller-manager deployment to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=5m -n openshift-cluster-csi-drivers deployments nutanix-csi-operator-controller-manager

## create nutanix csi custom resource
cat <<EOF | kubectl apply -f -
apiVersion: crd.nutanix.com/v1alpha1
kind: NutanixCsiStorage
metadata:
  name: nutanixcsistorage
  namespace: openshift-cluster-csi-drivers
spec:
  namespace: openshift-cluster-csi-drivers
  tolerations:
  - key: "node-role.kubernetes.io/infra"
    operator: "Exists"
    value: ""
    effect: "NoSchedule"
  openshift:
    masterIscsiConfig: true
    workerIscsiConfig: true
EOF

## create nutanix csi storage class
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nutanix-volume
provisioner: csi.nutanix.com
parameters:
  csi.storage.k8s.io/provisioner-secret-name: ntnx-secret
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-cluster-csi-drivers
  csi.storage.k8s.io/node-publish-secret-name: ntnx-secret
  csi.storage.k8s.io/node-publish-secret-namespace: openshift-cluster-csi-drivers
  csi.storage.k8s.io/controller-expand-secret-name: ntnx-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-cluster-csi-drivers
  csi.storage.k8s.io/fstype: ext4
  storageContainer: $NTNX_PE_STORAGE_CTR_NAME
  storageType: NutanixVolumes
  #whitelistIPMode: ENABLED
  #chapAuth: ENABLED
allowVolumeExpansion: true
reclaimPolicy: Delete
EOF

### set nutanix-volumes storage class to Default
kubectl annotate storageclasses.storage.k8s.io nutanix-volume storageclass.kubernetes.io/is-default-class=true

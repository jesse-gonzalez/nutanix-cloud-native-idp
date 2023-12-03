#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## set nutanix files variables needed for static and dynamic provision
NUTANIX_FILES_NFS_FQDN=@@{nutanix_files_nfs_fqdn}@@
NUTANIX_FILES_NFS_EXPORT=@@{nutanix_files_nfs_export}@@

echo "Configuring Nutanix Files Static Provisioner Storage Class"

# PRE-REQ: NFS Multi-Protocol needs to be configured on Files.  
# Also, Export should be set to Auth: System, Default Acccess: None, Client w/ RWX access Subnet and Anonymous GID/UID: 1024 and All Squash
# NUTANIX_FILES_NFS_FQDN=BootcampFS.ntnxlab.local
# NUTANIX_FILES_NFS_EXPORT=/kalm-main-nfs

cat <<EOF | kubectl apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
    name: nutanix-staticfile
    annotations:
        storageclass.kubernetes.io/is-default-class: "false"
provisioner: csi.nutanix.com
parameters:
    nfsServer: $(echo $NUTANIX_FILES_NFS_FQDN)
    nfsPath: $(echo $NUTANIX_FILES_NFS_EXPORT)
    storageType: NutanixFiles
EOF

# validate storage class
kubectl describe sc nutanix-staticfile

echo "Configuring Dynamic Nutanix Files Provisioner Storage Class"

NTNX_FILES_SERVER=$(echo $NUTANIX_FILES_NFS_FQDN | cut -d . -f1)
NTNX_DYNAMIC_SECRET=$(kubectl get secrets -n openshift-cluster-csi-drivers -o name | grep ntnx-secret | cut -d/ -f2)
# NTNX_FILES_SERVER=BootcampFS

### configure nutanix-dynamic files 
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nutanix-dynamicfile
parameters:
  csi.storage.k8s.io/controller-expand-secret-name: ntnx-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-cluster-csi-drivers
  csi.storage.k8s.io/node-publish-secret-name: ntnx-secret
  csi.storage.k8s.io/node-publish-secret-namespace: openshift-cluster-csi-drivers
  csi.storage.k8s.io/provisioner-secret-name: ntnx-secret
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-cluster-csi-drivers
  dynamicProv: ENABLED
  nfsServerName: $NTNX_FILES_SERVER
  storageType: NutanixFiles
  squashType: all-squash
provisioner: csi.nutanix.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF

# validate storage class
kubectl describe sc nutanix-dynamicfile

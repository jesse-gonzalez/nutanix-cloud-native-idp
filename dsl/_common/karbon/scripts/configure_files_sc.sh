
echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

echo "Set KUBECONFIG"
karbonctl cluster kubeconfig --cluster-name @@{k8s_cluster_name}@@ | tee ~/@@{k8s_cluster_name}@@.cfg ~/.kube/@@{k8s_cluster_name}@@.cfg

export KUBECONFIG=~/@@{k8s_cluster_name}@@.cfg

echo "Configuring Nutanix Files Static Provisioner Storage Class"

# PRE-REQ: NFS Multi-Protocol needs to be configured on Files.  
# Also, Export should be set to Auth: System, Default Acccess: None, Client w/ RWX access Subnet and Anonymous GID/UID: 1024 and All Squash
# NUTANIX_FILES_NFS_FQDN=BootcampFS.ntnxlab.local
# NUTANIX_FILES_NFS_EXPORT=/kalm-main-nfs

NUTANIX_FILES_NFS_FQDN=@@{nutanix_files_nfs_fqdn}@@
NUTANIX_FILES_NFS_EXPORT=@@{nutanix_files_nfs_export}@@

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


NUTANIX_FILES_NFS_FQDN=BootcampFS.ntnxlab.local
NTNX_FILES_SERVER=$(echo $NUTANIX_FILES_NFS_FQDN | cut -d . -f1)
NTNX_DYNAMIC_SECRET=$(kubectl get secrets -n kube-system -o name | grep ntnx-secret | cut -d/ -f2)
# NTNX_FILES_SERVER=BootcampFS

### configure nutanix-dynamic files 
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nutanix-dynamicfile
parameters:
  csi.storage.k8s.io/controller-expand-secret-name: $NTNX_DYNAMIC_SECRET
  csi.storage.k8s.io/controller-expand-secret-namespace: kube-system
  csi.storage.k8s.io/node-publish-secret-name: $NTNX_DYNAMIC_SECRET
  csi.storage.k8s.io/node-publish-secret-namespace: kube-system
  csi.storage.k8s.io/provisioner-secret-name: $NTNX_DYNAMIC_SECRET
  csi.storage.k8s.io/provisioner-secret-namespace: kube-system
  dynamicProv: ENABLED
  nfsServerName: $NTNX_FILES_SERVER
  storageType: NutanixFiles
provisioner: csi.nutanix.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF

# validate storage class
kubectl describe sc nutanix-dynamicfile

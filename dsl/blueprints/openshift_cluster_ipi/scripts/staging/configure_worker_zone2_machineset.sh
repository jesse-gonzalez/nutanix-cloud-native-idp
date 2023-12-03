## Create Machineset from previous template just modifiying the instance type
for MACHINESET in $(kubectl get -n openshift-machine-api machinesets -o name | grep -v ocs )
do
  oc get -n openshift-machine-api "$MACHINESET" -o json | jq '
      del( .metadata.uid, .metadata.managedFields, .metadata.selfLink, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.generation, .status) | 
      (.metadata.name, .spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"], .spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"]) |= sub("worker";"workerocs") | 
      (.spec.template.spec.providerSpec.value.instanceType) |= "m5.4xlarge" |
      (.spec.template.spec.metadata.labels["cluster.ocs.openshift.io/openshift-storage"]) |= ""' | kubectl apply --dry-run=client -o yaml -f -
done

## If using a RHPDS env with single AZ, create 3 replicas in same AZ.
if [ $(oc get -n openshift-machine-api machinesets -o name | grep ocs | wc -l) -eq 1 ]
then
   OCS_MACHINESET=$(oc get -n openshift-machine-api machinesets -o name | grep ocs)
   oc scale -n openshift-machine-api "$OCS_MACHINESET" --replicas=3
fi


OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

OCP_INFRA_NODE_REPLICA_COUNT=@@{infra_machineset_count}@@

OCP_CLUSTER_NAME=kalm-main-20-1-ocp
OCP_INFRA_NODE_REPLICA_COUNT=1
NTNX_PE_CLUSTER_UUID=0005f45c-dd5d-80de-03b3-ac1f6b1e8e69
NTNX_PE_NETWORK_UUID=4b4d7582-e04e-4c77-971c-7c5f942dee88
REGION=us-east-1
ZONE=a
MACHINE_ROLE=infra
MACHINE_NAME_SUFFIX=$MACHINE_ROLE-$REGION$ZONE

## create infra-user-data secret vs. using worker-user-data
#kubectl get secret worker-user-data -n openshift-machine-api -o json | sed 's/worker-user-data/worker-user-data/g' | kubectl apply -n openshift-machine-api -f -

## one liner to create machineset from existing worker machineset
#kubectl get $(kubectl get machineset -n openshift-machine-api --output=name) -n openshift-machine-api -o json | sed 's/worker/worker/g' | jq '.spec.template.spec +={"metadata":{"labels":{"node-role.kubernetes.io/worker":""}},"taints":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/worker"}]}' | kubectl apply -n openshift-machine-api -f -

CLUSTER_API_CLUSTER_ID=$(kubectl get machineset -n openshift-machine-api | grep worker | cut -d' ' -f 1 | sed 's/-worker//g')
MACHINESET_CLUSTER_ID=$(kubectl get machineset -n openshift-machine-api | grep worker | cut -d' ' -f 1 | sed "s/-worker/-${MACHINE_NAME_SUFFIX}/g")

CLUSTER_API_CLUSTER_ID=kalm-main-20-1-ocp-vnfld
MACHINESET_CLUSTER_ID=kalm-main-20-2-ocp-vnfld

NTNX_PE_CLUSTER_UUID=@@{prism_element_uuid}@@
NTNX_PE_NETWORK_UUID=@@{network_uuid}@@

cat <<EOF | kubectl apply -f -
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: $CLUSTER_API_CLUSTER_ID
  name: $MACHINESET_CLUSTER_ID-worker
  namespace: openshift-machine-api
spec:
  deletePolicy: Oldest
  replicas: $OCP_INFRA_NODE_REPLICA_COUNT
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: $CLUSTER_API_CLUSTER_ID
      machine.openshift.io/cluster-api-machineset: $MACHINESET_CLUSTER_ID-worker
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: $CLUSTER_API_CLUSTER_ID
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: $MACHINESET_CLUSTER_ID-worker
    spec:
      lifecycleHooks: {}
      metadata:
        labels:
          node-role.kubernetes.io/worker: ""
          cluster.ocs.openshift.io/openshift-storage: ""
      providerSpec:
        value:
          apiVersion: machine.openshift.io/v1
          cluster:
            type: uuid
            uuid: $NTNX_PE_CLUSTER_UUID
          credentialsSecret:
            name: nutanix-credentials
          image:
            name: $CLUSTER_API_CLUSTER_ID-rhcos
            type: name
          kind: NutanixMachineProviderConfig
          memorySize: 24Gi
          metadata:
            creationTimestamp: null
          subnets:
          - type: uuid
            uuid: $NTNX_PE_NETWORK_UUID
          systemDiskSize: 200Gi
          userDataSecret:
            name: worker-user-data
          vcpuSockets: 4
          vcpusPerSocket: 2
EOF

## scale cluster to expected count
##kubectl scale --replicas=$OCP_INFRA_NODE_REPLICA_COUNT $(kubectl get machineset -n openshift-machine-api --output=name | grep worker) -n openshift-machine-api

## To change VM Specs on any available MachineSet. Reconcile does not respect CPU/RAM right now, it is needed to change deletePolicy and scaleup/down
## kubectl patch -n openshift-machine-api $(kubectl get machineset -n openshift-machine-api --output=name) --type merge --patch '{"spec":{"deletePolicy": "Oldest"}}'

## wait for worker nodes to be ready

while [[ -z $(kubectl get machine -l machine.openshift.io/cluster-api-machine-type=worker -n openshift-machine-api 2>/dev/null) ]]; do
  echo "Waiting for worker machines to be created..."
  sleep 30
done

kubectl wait --for=jsonpath='{.status.phase}'=Running machine --timeout=20m -l machine.openshift.io/cluster-api-machine-type=worker -n openshift-machine-api
sleep 10s ## to handle api server disconnect failures, needs further investigation

while [[ -z $(kubectl get node -l node-role.kubernetes.io/worker= 2>/dev/null) ]]; do
  echo "Waiting for worker nodes to be ready..."
  sleep 30
done

kubectl wait --for=condition=Ready node --timeout=20m -l node-role.kubernetes.io/worker=
sleep 10s ## to handle api server disconnect failures, needs further investigation

## validate
kubectl get machines,nodes -o wide

## configure taints on secondary cluster

cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  key: MTAuMzguMTEuNzE6OTQ0MDphZG1pbjpudG54U0FTLzR1IQ==
kind: Secret
metadata:
  name: ntnx-secret-az2
  namespace: openshift-cluster-csi-drivers
type: Opaque
EOF

cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nutanix-volume-az2
parameters:
  csi.storage.k8s.io/controller-expand-secret-name: ntnx-secret-az2
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-cluster-csi-drivers
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/node-publish-secret-name: ntnx-secret-az2
  csi.storage.k8s.io/node-publish-secret-namespace: openshift-cluster-csi-drivers
  csi.storage.k8s.io/provisioner-secret-name: ntnx-secret-az2
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-cluster-csi-drivers
  storageContainer: Default
  storageType: NutanixVolumes
provisioner: csi.nutanix.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF


cat <<EOF | kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim-az2
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: nutanix-volume-az2
  volumeMode: Filesystem
---
apiVersion: v1
kind: Pod
metadata:
  name: example
  labels:
    app: httpd
  namespace: default
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: httpd
      image: 'image-registry.openshift-image-registry.svc:5000/openshift/httpd:latest'
      ports:
        - containerPort: 8080
      volumeMounts:
        - mountPath: /mount/test 
          name: test-volume
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
      nodeSelector:
        machine.openshift.io/cluster-api-machineset: kalm-main-11-2-ocp-vnfld-worker
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-claim-az2
EOF

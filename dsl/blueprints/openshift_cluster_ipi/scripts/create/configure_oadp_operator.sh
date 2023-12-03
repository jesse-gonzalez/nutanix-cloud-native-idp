#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

OBJECTS_ACCESS_KEY=@@{Objects S3 Access Key.username}@@
OBJECTS_SECRET_KEY=@@{Objects S3 Access Key.secret}@@
OBJECTS_STORE_ENDPOINT=https://@@{objects_store_dns_fqdn}@@

OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

OPERATOR_NS=openshift-adp
OPERATOR_NAME=redhat-oadp-operator
OPERATOR_CHANNEL=stable-1.1

## kubectl create operator namespace
kubectl create ns $OPERATOR_NS --dry-run=client -o yaml | kubectl apply -f -

## Annotate the oadp-operator project (namespace) so that Restic pods can be scheduled on all nodes.
kubectl annotate namespace $OPERATOR_NS openshift.io/node-selector="" --overwrite

## kubectl create operatorgroup
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: $OPERATOR_NAME-opgroup
  namespace: $OPERATOR_NS
spec:
  targetNamespaces:
  - $OPERATOR_NS
EOF

kubectl get operatorgroup -n $OPERATOR_NS

## get options: kubectl describe packagemanifests redhat-oadp-operator -n openshift-marketplace
## kubectl install operator from openshift-marketplace
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $OPERATOR_NAME
  namespace: $OPERATOR_NS
spec:
  config:
    tolerations:
    - key: "node-role.kubernetes.io/infra"
      operator: "Exists"
      value: ""
      effect: "NoSchedule"
  channel: $OPERATOR_CHANNEL
  name: $OPERATOR_NAME
  installPlanApproval: Automatic
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

while [[ -z $(kubectl get deployment -l olm.owner.namespace=$OPERATOR_NS -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for operator-controller-manager deployment to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=5m -n $OPERATOR_NS $(kubectl get deployment -n $OPERATOR_NS -o name)

### configure custom resources
## create Secret in OADP Namespace
cat << EOF > $OCP_BUILD_CACHE_BASE/credentials-velero
[default]
aws_access_key_id=$OBJECTS_ACCESS_KEY
aws_secret_access_key=$OBJECTS_SECRET_KEY
EOF

kubectl create secret generic cloud-credentials -n $OPERATOR_NS --from-file cloud=$OCP_BUILD_CACHE_BASE/credentials-velero --dry-run=client -o yaml | kubectl apply -f -

## create dataprotectionapplication custom resource

cat <<EOF | kubectl apply -f -
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: oadp-dpa-ntnx
  namespace: $OPERATOR_NS
spec:
  configuration:
    velero:
      defaultPlugins:
      - openshift
      - aws
      podConfig:
        resourceAllocations:
          limits:
            cpu: "1"
            memory: 512Mi
          requests:
            cpu: 500m
            memory: 256Mi
    restic:
      enable: true
      podConfig:
        resourceAllocations:
          limits:
            cpu: "1"
            memory: 4Gi
          requests:
            cpu: 500m
            memory: 256Mi
  backupImages: false
  backupLocations:
    - velero:
        provider: aws
        default: true
        objectStorage:
          bucket: oadp
          prefix: velero
        config:
          region: us-east-1
          s3ForcePathStyle: "true"
          s3Url: $OBJECTS_STORE_ENDPOINT
          insecureSkipTLSVerify: "true"
        credential:
          key: cloud
          name: cloud-credentials
EOF

kubectl get dataprotectionapplications.oadp.openshift.io oadp-dpa-ntnx -n $OPERATOR_NS

## validate

# ## configure volumesnapshot class
# cat <<EOF | kubectl apply -f -
# apiVersion: snapshot.storage.k8s.io/v1
# kind: VolumeSnapshotClass
# metadata:
#   name: nutanix-snapshot-class
#   labels:
#     velero.io/csi-volumesnapshot-class: "true"
# driver: csi.nutanix.com
# parameters:
#   storageType: NutanixVolumes
#   csi.storage.k8s.io/snapshotter-secret-name: ntnx-secret
#   csi.storage.k8s.io/snapshotter-secret-namespace: openshift-cluster-csi-drivers
# deletionPolicy: Delete
# EOF

## view all oadp resources
kubectl get all -n openshift-adp

## validate backupstorage locations
kubectl describe backupStorageLocations oadp-dpa-ntnx-1 -n openshift-adp


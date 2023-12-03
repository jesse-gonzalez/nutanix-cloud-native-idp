#!/bin/bash
set -e
set -o pipefail


# OCP_CLUSTER_NAME=kalm-main-11-4-ocp
# OBJECTS_ACCESS_KEY='5Y-4ByO99GEcD9BAU0hoN5fZoYSzsb2W'
# OBJECTS_SECRET_KEY=''
# OBJECTS_STORE_ENDPOINT='ntnx-objects.ntnxlab.local'
# NTNX_PC_FQDN=prism-central.kalm-main-11-4-ocp.ncnlabs.ninja
# NTNX_PC_IP=10.38.11.201
# NTNX_PC_PORT=9440
# NTNX_PC_USER=admin
# NTNX_PC_PASS=''

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

OBJECTS_ACCESS_KEY='@@{Objects S3 Access Key.username}@@'
OBJECTS_SECRET_KEY='@@{Objects S3 Access Key.secret}@@'
OBJECTS_STORE_ENDPOINT='@@{objects_store_dns_fqdn}@@'

NTNX_PC_FQDN=@@{ocp_ntnx_pc_dns_fqdn}@@
NTNX_PC_IP=@@{pc_instance_ip}@@
NTNX_PC_PORT=@@{pc_instance_port}@@
NTNX_PC_USER=@@{Prism Central User.username}@@
NTNX_PC_PASS=@@{Prism Central User.secret}@@

OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

### Deploy the COSI Framework + Nutanix driver

## Create a secret for Objects
cat <<EOF | tee $OCP_BUILD_CACHE_BASE/secret.yaml
account_name: "cosiaccount"
pc_secret: "$NTNX_PC_FQDN:$NTNX_PC_PORT:$NTNX_PC_USER:$NTNX_PC_PASS"
endpoint: $OBJECTS_STORE_ENDPOINT
access_key: $OBJECTS_ACCESS_KEY
secret_key: $OBJECTS_SECRET_KEY
EOF

## kubectl create operator namespace
kubectl create ns cosi-driver --dry-run=client -o yaml | kubectl apply -f -

## install helm chart from local
helm install ntnx-cosi ./cosi-driver-0.0.1.tgz -n cosi-driver -f $OCP_BUILD_CACHE_BASE/secret.yaml \
  --create-namespace \
  --wait \
  --wait-for-jobs

oc project cosi-driver
oc adm policy add-scc-to-user -z objectstorage-csi-adapter-sa privileged

## create a BucketClass

cat <<EOF | kubectl apply -f -
kind: BucketClass
apiVersion: objectstorage.k8s.io/v1alpha1
metadata:
  name: nutanix-objects
driverName: ntnx.objectstorage.k8s.io
deletionPolicy: Delete
EOF

## create BucketAccessClass

cat <<EOF | kubectl apply -f -
kind: BucketAccessClass
apiVersion: objectstorage.k8s.io/v1alpha1
metadata:
  name: nutanix-objects-bac
driverName: ntnx.objectstorage.k8s.io
authenticationType: KEY
EOF

### ===== Demo start here =====
### Test the COSI integration

### create BucketClaim

cat <<EOF | kubectl apply -f -
kind: BucketClaim
apiVersion: objectstorage.k8s.io/v1alpha1
metadata:
  name: demo-bucket
spec:
  bucketClassName: nutanix-objects
  protocols:
  - s3
EOF

## grant bucket access

cat <<EOF | kubectl apply -f -
kind: BucketAccess
apiVersion: objectstorage.k8s.io/v1alpha1
metadata:
  name: demo-ba
spec:
  bucketClaimName: demo-bucket
  protocol: s3
  bucketAccessClassName: demo-bac
  credentialsSecretName: bucketcreds
EOF

## validate all 

kubectl get bucketaccessclasses,bucketaccesses,bucketclaims,bucketclasses,buckets

## consume bucket (awscli example)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: awscli
spec:
  containers:
    - name: awscli
      image: pknutanix/aws-cli:1.16.220
      stdin: true
      tty: true
      volumeMounts:
        - name: cosi-secrets
          mountPath: /var/run/secrets/cosi
  volumes:
  - name: cosi-secrets
    secret:
      secretName: bucketcreds
EOF

## Show access info mounted on `/var/run/secrets/cosi/BucketInfo`

kubectl exec awscli -- cat /var/run/secrets/cosi/BucketInfo | jq .spec

## Set values of dynamically generated info of bucket creds

BUCKETID=$(kubectl get secret bucketcreds -o jsonpath='{.data.BucketInfo}' | base64 -d | jq -r .spec.bucketName)
ENDPOINT=$(kubectl get secret bucketcreds -o jsonpath='{.data.BucketInfo}' | base64 -d | jq -r .spec.secretS3.endpoint)
ACCESS_KEY=$(kubectl get secret bucketcreds -o jsonpath='{.data.BucketInfo}' | base64 -d | jq -r .spec.secretS3.accessKeyID)
SECRET_KEY=$(kubectl get secret bucketcreds -o jsonpath='{.data.BucketInfo}' | base64 -d | jq -r .spec.secretS3.accessSecretKey)

echo $BUCKETID
echo $ENDPOINT
echo $ACCESS_KEY
echo $SECRET_KEY

## list buckets
kubectl exec awscli -- sh -c "AWS_ACCESS_KEY_ID=$ACCESS_KEY AWS_SECRET_ACCESS_KEY=$SECRET_KEY aws s3api --no-verify-ssl --endpoint-url https://$ENDPOINT list-buckets"

## put object into bucket
kubectl exec awscli -- sh -c "echo 'hello, hi there' > data.txt"
kubectl exec awscli -- sh -c "AWS_ACCESS_KEY_ID=$ACCESS_KEY AWS_SECRET_ACCESS_KEY=$SECRET_KEY aws s3api --no-verify-ssl --endpoint-url https://$ENDPOINT put-object --bucket $BUCKETID --key data.txt --body data.txt"

## get object from bucket
kubectl exec awscli -- sh -c "AWS_ACCESS_KEY_ID=$ACCESS_KEY AWS_SECRET_ACCESS_KEY=$SECRET_KEY aws s3api --no-verify-ssl --endpoint-url https://$ENDPOINT get-object --bucket $BUCKETID --key data.txt data.log && cat data.log"

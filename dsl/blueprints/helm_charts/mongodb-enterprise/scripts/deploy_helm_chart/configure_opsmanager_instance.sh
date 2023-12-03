WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

MONGODB_USER=@@{MongoDB User.username}@@
MONGODB_PASS=@@{MongoDB User.secret}@@

## Create OpsManager Instance

# OPSMANAGER_VERSION="5.0.10"
# OPSMANAGER_APPDB_VERSION="4.2.6-ent"

# OPSMANAGER_REPLICASET_COUNT="3"
# OPSMANAGER_APPDB_REPLICASET_COUNT="3"

OPSMANAGER_VERSION="@@{opsmanager_version}@@"
OPSMANAGER_APPDB_VERSION="@@{opsmanager_appdb_version}@@"

OPSMANAGER_REPLICASET_COUNT=@@{opsmanager_replicaset_count}@@
OPSMANAGER_APPDB_REPLICASET_COUNT=@@{opsmanager_appdb_replicaset_count}@@

cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: om-admin-secret
type: Opaque
stringData:
  Username: $( echo $MONGODB_USER )
  Password: $( echo $MONGODB_PASS )
  FirstName: mongodb-opsmanager
  LastName: admin
---
apiVersion: mongodb.com/v1
kind: MongoDBOpsManager
metadata:
  name: mongodb-opsmanager
spec:
  replicas: $( echo $OPSMANAGER_REPLICASET_COUNT )
  version: $( echo $OPSMANAGER_VERSION )
  adminCredentials: om-admin-secret
  externalConnectivity:
    type: LoadBalancer
  applicationDatabase:
    members: $( echo $OPSMANAGER_APPDB_REPLICASET_COUNT )
    version: $( echo $OPSMANAGER_APPDB_VERSION )
  configuration:
    mms.ignoreInitialUiSetup: "true"
    automation.versions.source: "remote"
    mms.adminEmailAddr: cloud-admin@no-reply.com
    mms.fromEmailAddr: cloud-support@no-reply.com
    mms.mail.hostname: email-smtp.nutanix.demo
    mms.mail.port: "465"
    mms.mail.ssl: "false"
    mms.mail.transport: smtp
    mms.minimumTLSVersion: TLSv1.2
    mms.replyToEmailAddr: cloud-support@no-reply.com
EOF

## Wait for pods to create before waiting for ready state

while [[ -z $(kubectl get pod -l app=mongodb-opsmanager-db-svc -n ${NAMESPACE} 2>/dev/null) ]]; do
  echo "still waiting for pods with a label of mongodb-opsmanager-db-svc to be created"
  sleep 1
done

kubectl wait --for=condition=Ready pod -l app=mongodb-opsmanager-db-svc --timeout=5m -n ${NAMESPACE}

while [[ -z $(kubectl get pod -l app=mongodb-opsmanager-svc -n ${NAMESPACE} 2>/dev/null) ]]; do
  echo "still waiting for pods with a label of mongodb-opsmanager-svc to be created"
  sleep 1
done

kubectl wait --for=condition=Ready pod -l app=mongodb-opsmanager-svc --timeout=15m -n ${NAMESPACE}

while [[ -z $(kubectl get pod -l app=mongodb-opsmanager-backup-daemon-svc -n ${NAMESPACE} 2>/dev/null) ]]; do
  echo "still waiting for pods with a label of mongodb-opsmanager-backup-daemon-svc to be created"
  sleep 1
done

kubectl wait --for=condition=Ready pod -l app=mongodb-opsmanager-backup-daemon-svc --timeout=10m -n ${NAMESPACE}

## PRINT OUT VARS

echo -e "\nTo Register New MongoDB Instance from external K8s cluster, you can gather the OpsManager URL and API Keys by printing out the variables on Overview tab\n"

OPSMANAGER_NAMESPACE=${NAMESPACE}
OPSMANAGER_HOST=$(kubectl get svc mongodb-opsmanager-svc-ext -n ${OPSMANAGER_NAMESPACE} -o jsonpath="{.status.loadBalancer.ingress[].ip}")
OPSMANAGER_BASE_URL="http://opsmanager.${OPSMANAGER_HOST}.nip.io:8080"
OPSMANAGER_API_USER=$(kubectl get secrets mongodb-enterprise-mongodb-opsmanager-admin-key -n ${OPSMANAGER_NAMESPACE} -o jsonpath='{.data.publicKey}' | base64 -d)
OPSMANAGER_API_KEY=$(kubectl get secrets mongodb-enterprise-mongodb-opsmanager-admin-key -n ${OPSMANAGER_NAMESPACE} -o jsonpath='{.data.privateKey}' | base64 -d)
OPSMANAGER_ORG_ID=$(curl -u ${OPSMANAGER_API_USER}:${OPSMANAGER_API_KEY} --digest -s --request GET "${OPSMANAGER_HOST}:8080/api/public/v1.0/orgs?pretty=true" | jq -r '.results[].id')

echo "OPSMANAGER_API_KEY=${OPSMANAGER_API_KEY}"
echo "OPSMANAGER_API_USER=${OPSMANAGER_API_USER}"
echo "OPSMANAGER_ORG_ID=${OPSMANAGER_ORG_ID}"
echo "OPSMANAGER_BASE_URL=${OPSMANAGER_BASE_URL}"

echo -e "\nNavigate to ${OM_BASE_URL} via browser to access OpsManager instance
\nAfter reaching the UI the first time you can login with username: 'admin'
\nThe password can be found by running:
\nkubectl get secret om-admin-secret -o jsonpath='{.data.Password}' -n ${NAMESPACE} | base64 -d && echo"


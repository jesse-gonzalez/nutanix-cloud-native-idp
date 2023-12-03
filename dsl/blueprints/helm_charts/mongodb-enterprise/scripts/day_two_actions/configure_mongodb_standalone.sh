WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{Helm_MongodbEnterprise.nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

MONGODB_USER=@@{MongoDB User.username}@@
MONGODB_PASS=@@{MongoDB User.secret}@@

## if user provided a value for OM Base URL, then use that - otherise query k8s secrets / configs
OM_BASE_URL="@@{opsmanager_base_url}@@"
if [ "${OM_BASE_URL}" == "" ]
then
  OM_BASE_URL="http://${NIPIO_INGRESS_DOMAIN}:8080"
fi

## if user provided a value for API User, then use that - otherise query k8s secrets / configs
OM_API_USER="@@{opsmanager_api_user}@@"
if [ "${OM_API_USER}" == "" ]
then
  OM_API_USER=$(kubectl get secrets mongodb-enterprise-mongodb-opsmanager-admin-key -n ${NAMESPACE} -o jsonpath='{.data.publicKey}' | base64 -d)
fi

## if user provided a value for API Key, then use that - otherise query k8s secrets / configs
OM_API_KEY="@@{opsmanager_api_key}@@"
if [ "${OM_API_KEY}" == "" ]
then
  OM_API_KEY=$(kubectl get secrets mongodb-enterprise-mongodb-opsmanager-admin-key -n ${NAMESPACE} -o jsonpath='{.data.privateKey}' | base64 -d)
fi

## if user provided a value for Organization, then use that - otherise query k8s secrets / configs
OM_ORG_ID="@@{opsmanager_org_id}@@"
if [ "${OM_ORG_ID}" == "" ]
then
  OM_ORG_ID=$(curl --user ${OM_API_USER}:${OM_API_KEY} --digest -s --request GET "${NIPIO_INGRESS_DOMAIN}:8080/api/public/v1.0/orgs?pretty=true" | jq -r '.results[].id')
fi

#MONGODB_APPDB_VERSION="4.2.6-ent"

MONGODB_APPDB_VERSION="@@{mongodb_appdb_version}@@"
MONGODB_APPDB_CONTAINER_IMAGE="@@{mongodb_appdb_container_image}@@"

MONGODB_APPDB_CPU_LIMITS="@@{mongodb_appdb_cpu_limits}@@"
MONGODB_APPDB_MEM_LIMITS="@@{mongodb_appdb_mem_limits}@@"

MONGODB_APPDB_DATA_SIZE="@@{mongodb_appdb_data_size}@@"
MONGODB_APPDB_JOURNAL_SIZE="@@{mongodb_appdb_logs_size}@@"
MONGODB_APPDB_LOGS_SIZE="@@{mongodb_appdb_journal_size}@@"

MONGODB_APPDB_STORAGE_CLASS="@@{mongodb_appdb_storage_class}@@"

## Setting MongoDB Namespace to OpsManager Project Manager

MONGODB_STANDALONE_INSTANCE_NAME="@@{mongodb_standalone_instance_name}@@"

OM_PROJECT_NAME="${MONGODB_STANDALONE_INSTANCE_NAME}"
MONGODB_DEFAULT_SCRAM_USER="mongodb-user-${RANDOM}"
MONGODB_NAMESPACE="${OM_PROJECT_NAME}"

## create MONGODB Namespace if it doesn't exist
kubectl create ns ${MONGODB_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
kubectl label ns ${MONGODB_NAMESPACE} mongodb.com/instance=true

## creating service account needed for operator
kubectl create sa mongodb-enterprise-database-pods --namespace ${MONGODB_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

##############
## Create Organization Secret & ConfigMap for Project

kubectl -n ${MONGODB_NAMESPACE} create secret generic organization-secret \
  --from-literal="user=$OM_API_USER" \
  --from-literal="publicApiKey=$OM_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -n ${MONGODB_NAMESPACE} -f -

cat <<EOF | kubectl apply -n ${MONGODB_NAMESPACE} -f -
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: $( echo $OM_PROJECT_NAME )-config
data:
  baseUrl: $( echo $OM_BASE_URL )
  projectName: $( echo $OM_PROJECT_NAME )-project
  orgId: $( echo $OM_ORG_ID )
EOF

##############
## Create MongoDB Standalone Instance and Database User in Target Namespace

cat <<EOF | kubectl apply -n ${MONGODB_NAMESPACE} -f -
---
apiVersion: mongodb.com/v1
kind: MongoDB
metadata:
  name: $( echo $OM_PROJECT_NAME )
spec:
  version: $( echo $MONGODB_APPDB_VERSION )
  type: Standalone
  opsManager:
    configMapRef:
      name: $( echo $OM_PROJECT_NAME )-config
  credentials: organization-secret
  persistent: true
  exposedExternally: true
  podSpec:
    podTemplate:
      spec:
        containers:
          - name: $( echo $MONGODB_APPDB_CONTAINER_IMAGE )
            resources:
              limits:
                cpu: $( echo $MONGODB_APPDB_CPU_LIMITS )
                memory: $( echo $MONGODB_APPDB_MEM_LIMITS )
            requests:
              cpu: $( echo $MONGODB_APPDB_CPU_LIMITS )
              memory: $( echo $MONGODB_APPDB_MEM_LIMITS )
        tolerations:
        - key: karbon-node-pool
          operator: Exists
          effect: NoSchedule
    persistence:
      multiple:
        data:
          storage: $( echo $MONGODB_APPDB_DATA_SIZE )
        journal:
          storage: $( echo $MONGODB_APPDB_JOURNAL_SIZE )
        logs:
          storage: $( echo $MONGODB_APPDB_LOGS_SIZE )
EOF

##############
## Create MongoDB Database User

cat <<EOF | kubectl apply -n ${MONGODB_NAMESPACE} -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: $( echo $MONGODB_DEFAULT_SCRAM_USER )-password
type: Opaque
stringData:
  password: $( echo $MONGODB_PASS )
---
apiVersion: mongodb.com/v1
kind: MongoDBUser
metadata:
  name: $( echo $MONGODB_DEFAULT_SCRAM_USER )
spec:
  passwordSecretKeyRef:
    name: $( echo $MONGODB_DEFAULT_SCRAM_USER )-password
    key: password
  username: $( echo $MONGODB_DEFAULT_SCRAM_USER )
  db: "admin"
  mongodbResourceRef:
    name: $( echo $OM_PROJECT_NAME )
    # Match to MongoDB resource using authenticaiton
  roles:
  - db: "admin"
    name: "clusterAdmin"
  - db: "admin"
    name: "userAdminAnyDatabase"
  - db: "admin"
    name: "readWrite"
  - db: "admin"
    name: "userAdminAnyDatabase"
EOF

while [[ -z $(kubectl get pod -l app=${OM_PROJECT_NAME}-svc -n ${MONGODB_NAMESPACE} 2>/dev/null) ]]; do
  echo "still waiting for pods with a label of ${OM_PROJECT_NAME}-svc to be created"
  sleep 1
done

kubectl wait --for=condition=Ready pod -l app=${OM_PROJECT_NAME}-svc --timeout=15m -n ${MONGODB_NAMESPACE}

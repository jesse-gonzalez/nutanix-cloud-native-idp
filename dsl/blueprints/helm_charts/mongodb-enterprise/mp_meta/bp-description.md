


#### Connectivity Details

OpsManager URL and API Keys for Deploying MongoDB AppDB:

```bash
OPSMANAGER_HOST=$(kubectl get svc mongodb-opsmanager-svc-ext -n mongodb-enterprise -o jsonpath="{.status.loadBalancer.ingress[].ip}")
OM_BASE_URL="http://opsmanager.${OPSMANAGER_HOST}.nip.io:8080"
```

```bash
OPSMANAGER_API_USER=$(kubectl get secrets mongodb-enterprise-mongodb-opsmanager-admin-key -n mongodb-enterprise -o jsonpath='{.data.publicKey}' | base64 -d)
OPSMANAGER_API_KEY=$(kubectl get secrets mongodb-enterprise-mongodb-opsmanager-admin-key -n mongodb-enterprise -o jsonpath='{.data.privateKey}' | base64 -d)
OPSMANAGER_ORG_ID=$(curl -u ${OPSMANAGER_API_USER}:${OPSMANAGER_API_KEY} --digest -s --request GET "${OPSMANAGER_HOST}:8080/api/public/v1.0/orgs?pretty=true" | jq -r '.results[].id')
```

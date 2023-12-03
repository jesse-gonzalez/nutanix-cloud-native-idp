WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

## configure admin user
RANCHER_USER=@@{Rancher User.username}@@
RANCHER_PASS=@@{Rancher User.secret}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

## See https://artifacthub.io/packages/helm/rancher-stable/rancher for additional helm options

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
helm upgrade --install ${INSTANCE_NAME} rancher-latest/rancher \
	--namespace ${NAMESPACE} \
	--set hostname=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} \
  --set bootstrapPassword="${RANCHER_PASS}" \
  --set replicas=3 \
	--set-string ingress.extraAnnotations."kubernetes\.io\/ingress\.class"=nginx \
	--wait

kubectl wait --for=condition=Ready -l app=rancher pod -A
kubectl wait --for=condition=Ready -l app=rancher-webhook pod -A

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

echo "Navigate to https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} via browser to access instance"

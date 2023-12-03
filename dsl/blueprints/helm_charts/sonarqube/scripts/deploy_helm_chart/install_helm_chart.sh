WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# this step will configure sonarqube with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add oteemocharts https://oteemo.github.io/charts
helm repo update
helm upgrade --install ${INSTANCE_NAME} oteemocharts/sonarqube \
	--namespace ${INSTANCE_NAME} \
	--set ingress.enabled=true \
	--set-string ingress.annotations."kubernetes\.io\/ingress\.class"=nginx \
	--set-string ingress.annotations."cert-manager\.io\/cluster-issuer"=selfsigned-cluster-issuer \
	--set ingress.hosts[0].name="${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}" \
	--set ingress.hosts[1]="${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN}" \
	--set ingress.tls[0].secretName=${INSTANCE_NAME}-tls \
	--set ingress.tls[0].hosts[0]="${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}" \
	--set ingress.tls[0].hosts[1]=${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN} \
	--wait
kubectl wait --for=condition=Ready -l release=sonarqube pod -n ${NAMESPACE}

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

echo "Navigate to https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} via browser to access instance"
echo "Alternatively, if DNS wildcard domain configured, navigate to https://${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN}"

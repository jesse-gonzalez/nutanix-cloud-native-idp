WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

## configure admin user
HARBOR_USER=@@{Harbor User.username}@@
HARBOR_PASS=@@{Harbor User.secret}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add harbor https://helm.goharbor.io
helm repo update
helm upgrade --install ${INSTANCE_NAME} harbor/harbor \
	--namespace ${NAMESPACE} \
	--set expose.type=ingress \
	--set expose.tls.enabled=auto \
	--set expose.ingress.controller=default \
	--set expose.ingress.hosts.core="${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}" \
	--set expose.ingress.hosts.notary="${INSTANCE_NAME}-notary.${NIPIO_INGRESS_DOMAIN}" \
	--set externalURL="https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}"\
	--set-string expose.ingress.annotations."kubernetes\.io\/ingress\.class"=nginx \
	--set-string expose.ingress.annotations."cert-manager\.io\/cluster-issuer"=selfsigned-cluster-issuer \
	--set harborAdminPassword="${HARBOR_PASS}" \
	--wait


	# --set expose.tls.secret.secretName=${INSTANCE_NAME}-tls \
	# --set expose.tls.secret.notarySecretName=${INSTANCE_NAME}-notary-tls \

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/part-of=harbor -n ${NAMESPACE}

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

echo "Navigate to https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} via browser to access instance"


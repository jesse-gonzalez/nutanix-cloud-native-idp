WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add jfrog https://charts.jfrog.io
helm repo update
helm upgrade --install ${INSTANCE_NAME} \
	--set artifactory.artifactory.persistence.size="1Ti" \
	--set artifactory.artifactory.service.type=ClusterIP \
	--set artifactory.nginx.enabled=false \
	--set artifactory.ingress.enabled=true \
  --set artifactory.ingress.defaultBackend.enabled=false \
	--set-string artifactory.ingress.annotations."kubernetes\.io\/ingress\.class"=nginx \
	--set-string artifactory.ingress.annotations."nginx\.ingress\.kubernetes\.io\/proxy-buffering"=off \
	--set-string artifactory.ingress.annotations."nginx\.ingress\.kubernetes\.io\/proxy-read-timeout"=1800 \
	--set-string artifactory.ingress.annotations."nginx\.ingress\.kubernetes\.io\/proxy-send-timeout"=1800 \
	--set-string artifactory.ingress.annotations."nginx\.ingress\.kubernetes\.io\/proxy-body-size"=0 \
	--set-string artifactory.ingress.annotations."nginx\.ingress\.kubernetes\.io\/force-ssl-redirect"=true \
	--set-string artifactory.ingress.annotations."cert-manager\.io\/cluster-issuer"=selfsigned-cluster-issuer \
	--set-string artifactory.ingress.hosts[0]="${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}" \
	--set artifactory.ingress.tls[0].hosts[0]=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} \
	--set artifactory.ingress.tls[0].secretName=${INSTANCE_NAME}-noip-tls \
	--set artifactory.ingress.hosts[1]="${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN}" \
	--set artifactory.ingress.tls[1].hosts[0]=${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN} \
	--set artifactory.ingress.tls[1].secretName=${INSTANCE_NAME}-wildcard-tls \
  --version 107.19.4 \
	--namespace ${NAMESPACE} jfrog/artifactory-jcr \
	--wait

kubectl wait --for=condition=Ready pod/${INSTANCE_NAME}-artifactory-0 --namespace ${NAMESPACE}

## scaling down due to inability to pass via helm chart
kubectl scale sts artifactory-jcr --replicas=1 --namespace ${NAMESPACE}

helm status ${INSTANCE_NAME} --namespace ${NAMESPACE}

echo "Navigate to  https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} via browser to access instance"
echo "Alternatively, if DNS wildcard domain configured, navigate to https://${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN}"

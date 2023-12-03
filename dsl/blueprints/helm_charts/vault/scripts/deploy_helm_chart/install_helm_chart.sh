WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm search repo hashicorp/vault
helm upgrade --install ${INSTANCE_NAME} hashicorp/vault \
	--namespace ${NAMESPACE} \
	--set server.dev.enabled=false \
	--set server.standalone.enabled=false \
	--set server.ha.enabled=true \
	--set server.ha.raft.enabled=true \
	--set server.ha.replicas=5 \
	--set ui.enabled=true \
	--set ui.activeVaultPodOnly=true \
	--set server.ingress.enabled=true \
	--set-string server.ingress.annotations."kubernetes\.io\/ingress\.class"=nginx \
	--set-string server.ingress.annotations."cert-manager\.io\/cluster-issuer"=selfsigned-cluster-issuer \
	--set-string server.ingress.annotations."nginx\.ingress\.kubernetes\.io\/force-ssl-redirect"=true \
	--set server.ingress.hosts[0].host="${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}" \
	--set server.ingress.tls[0].hosts[0]=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} \
	--set server.ingress.tls[0].secretName=${INSTANCE_NAME}-npio-tls \
	--set server.ingress.hosts[1].host="${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN}" \
	--set server.ingress.tls[1].hosts[0]=${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN} \
	--set server.ingress.tls[1].secretName=${INSTANCE_NAME}-wildcard-tls \
	--create-namespace \
	--wait-for-jobs \
	--wait

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault-agent-injector

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

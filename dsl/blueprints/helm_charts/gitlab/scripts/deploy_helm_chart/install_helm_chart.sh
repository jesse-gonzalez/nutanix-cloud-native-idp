WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
	--namespace ${NAMESPACE} \
  --timeout 15m \
  --set global.hosts.domain="${NIPIO_INGRESS_DOMAIN}" \
  --set nginx-ingress.enabled=false \
  --set certmanager.install=false \
	--set global.ingress.configureCertmanager=false \
	--set global.ingress.tls.enabled=true \
	--set global.ingress.annotations."cert-manager\.io\/cluster-issuer"=selfsigned-cluster-issuer \
  --set global.ingress.class=nginx \
	--set global.edition=ce \
	--set gitlab-runner.install=false \
	--set global.pages.enabled=true \
	--set gitlab.webservice.minReplicas=1 \
	--set gitlab.webservice.maxReplicas=2 \
	--set gitlab.sidekiq.minReplicas=1 \
	--set gitlab.sidekiq.maxReplicas=2 \
	--set gitlab.gitlab-shell.minReplicas=1 \
	--set gitlab.gitlab-shell.maxReplicas=2 \
	--set registry.hpa.minReplicas=1 \
	--set registry.hpa.maxReplicas=2 \
	--wait

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/part-of=gitlab -n ${NAMESPACE}

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

echo "Navigate to https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} via browser to access instance"

WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

## Set label on the system namespace

kubectl label ns/kube-system monitoring=k8s
kubectl label ns/ntnx-system monitoring=k8s

## Patch existing prometheus resource to limit ServiceMonitors used

kubectl -n ntnx-system patch --type merge prometheus/k8s -p '{"spec":{"serviceMonitorNamespaceSelector":{"matchLabels":{"monitoring": "k8s"}}}}'

curl -L https://gist.githubusercontent.com/tuxtof/d79df56efc029b06751eb374b79294f1/raw/45f5218963133e81b0b47d1a755bb88f368cb416/karbon-app-mon-step2-rbac.yml | kubectl apply -f -
curl -L https://gist.githubusercontent.com/tuxtof/7234af4ae5f841002fd5a21b2c59450e/raw/23499c77f0ef9e7179ca7ea9a0b38e425c610887/karbon-app-mon-step2-prom.yml | kubectl apply -f -
curl -L https://gist.githubusercontent.com/tuxtof/168b7c8f8e3e3d8492b67d8195b54ef0/raw/f0f86d154a5d406bfcdc94792879f34adeb88469/karbon-app-mon-step2-service-monitor.yml | kubectl apply -f -


# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install ${INSTANCE_NAME} grafana/grafana \
	--set replicas=1 \
	--set ingress.enabled=true \
	--set-string ingress.annotations."kubernetes\.io\/ingress\.class"=nginx \
	--set-string ingress.annotations."nginx\.ingress\.kubernetes\.io\/ssl-redirect"="true" \
	--set-string ingress.annotations."cert-manager\.io\/cluster-issuer"=selfsigned-cluster-issuer \
	--set ingress.hosts[0]=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} \
	--set ingress.tls[0].hosts[0]=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} \
	--set ingress.tls[0].secretName=${INSTANCE_NAME}-tls \
	--set ingress.hosts[1]=${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN} \
	--set ingress.tls[1].hosts[0]=${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN} \
	--set ingress.tls[1].secretName=${INSTANCE_NAME}-wildcard-tls \
	--set plugins={grafana-piechart-panel} \
	--set persistence.enabled=true \
	--set persistence.size=10Gi \
	--set datasources."datasources\.yaml".apiVersion=1 \
	--set datasources."datasources\.yaml".datasources[0].url='http://prometheus-k8s.ntnx-system.svc.cluster.local:9090' \
	--set datasources."datasources\.yaml".datasources[0].isDefault='true' \
	--set datasources."datasources\.yaml".datasources[0].access='proxy' \
	--set datasources."datasources\.yaml".datasources[0].editable='true' \
	--set datasources."datasources\.yaml".datasources[0].type='prometheus' \
	--set datasources."datasources\.yaml".datasources[0].name='prometheus-karbon' \
	--set datasources."datasources\.yaml".datasources[1].url='http://prometheus-apps.monitoring-apps.svc.cluster.local:9090' \
	--set datasources."datasources\.yaml".datasources[1].isDefault='false' \
	--set datasources."datasources\.yaml".datasources[1].access='proxy' \
	--set datasources."datasources\.yaml".datasources[1].editable='true' \
	--set datasources."datasources\.yaml".datasources[1].type='prometheus' \
	--set datasources."datasources\.yaml".datasources[1].name='prometheus-apps' \
	--set dashboards.default.kube-capacity.gnetId=7249 \
	--set dashboards.default.kube-capacity.revision=1 \
	--set dashboards.default.kube-capacity.datasource='prometheus-karbon' \
	--set dashboards.default.kube-capacity.gnetId=5309 \
	--set dashboards.default.kube-capacity.revision=1 \
	--set dashboards.default.kube-capacity.datasource='prometheus-karbon' \
	--set dashboards.default.kube-cluster-health.gnetId=5312 \
	--set dashboards.default.kube-cluster-health.revision=1 \
	--set dashboards.default.kube-cluster-health.datasource='prometheus-karbon' \
	--set dashboards.default.kube-cluster-status.gnetId=5315 \
	--set dashboards.default.kube-cluster-status.revision=1 \
	--set dashboards.default.kube-cluster-status.datasource='prometheus-karbon' \
	--set dashboards.default.kube-deployment.gnetId=5303 \
	--set dashboards.default.kube-deployment.revision=1 \
	--set dashboards.default.kube-deployment.datasource='prometheus-karbon' \
	--set dashboards.default.kube-master-status.gnetId=5318 \
	--set dashboards.default.kube-master-status.revision=1 \
	--set dashboards.default.kube-master-status.datasource='prometheus-karbon' \
	--set dashboards.default.kube-nodes.gnetId=5324 \
	--set dashboards.default.kube-nodes.revision=1 \
	--set dashboards.default.kube-nodes.datasource='prometheus-karbon' \
	--set dashboards.default.kube-pods.gnetId=5327 \
	--set dashboards.default.kube-pods.revision=1 \
	--set dashboards.default.kube-pods.datasource='prometheus-karbon' \
	--set dashboards.default.kube-resource-request.gnetId=5321 \
	--set dashboards.default.kube-resource-request.revision=1 \
	--set dashboards.default.kube-resource-request.datasource='prometheus-karbon' \
	--set dashboards.default.kube-statefulset.gnetId=5330 \
	--set dashboards.default.kube-statefulset.revision=1 \
	--set dashboards.default.kube-statefulset.datasource='prometheus-karbon' \
	--set dashboardProviders."dashboardproviders\.yaml".apiVersion=1 \
	--set dashboardProviders."dashboardproviders\.yaml".providers[0].orgId=1 \
	--set dashboardProviders."dashboardproviders\.yaml".providers[0].type=file \
	--set dashboardProviders."dashboardproviders\.yaml".providers[0].disableDeletion=false \
	--set dashboardProviders."dashboardproviders\.yaml".providers[0].options.path="/var/lib/grafana/dashboards/default" \
	--namespace=${NAMESPACE} \
	--wait
	#--dry-run --debug

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

echo "Navigate to https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} via browser to access instance

Alternatively, if DNS wildcard domain configured, navigate to https://${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN}"

echo "default admin passcode:"
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

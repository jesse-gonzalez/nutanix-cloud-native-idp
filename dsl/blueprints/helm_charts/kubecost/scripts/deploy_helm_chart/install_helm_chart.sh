WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

cat <<EOF | tee kubecost-p8s-scrape-values.yaml
prometheus:
  extraScrapeConfigs: |
    - job_name: kubecost
      honor_labels: true
      scrape_interval: 1m
      scrape_timeout: 10s
      metrics_path: /metrics
      scheme: http
      dns_sd_configs:
      - names:
        - {{ template "cost-analyzer.serviceName" . }}
        type: 'A'
        port: 9003
EOF

# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm repo update
helm upgrade --install ${INSTANCE_NAME} kubecost/cost-analyzer \
	--namespace ${NAMESPACE} \
  --set global.prometheus.enabled=false \
  --set global.prometheus.fqdn=http://prometheus-k8s.ntnx-system.svc.cluster.local:9090 \
  --set global.notifications.alertmanager.enabled=false \
  --set prometheus.kube-state-metrics.disabled=true \
  --set prometheus.nodeExporter.enabled=false \
  --set prometheusRule.enabled=false \
  --set serviceMonitor.enabled=false \
	--set ingress.enabled=false \
  --values kubecost-p8s-scrape-values.yaml \
  --create-namespace \
	--wait

## test prometheus request
## kubectl exec kubecost-cost-analyzer-865578f9d4-pm9sc -c cost-analyzer-frontend -n kubecost -- curl http://prometheus-k8s.ntnx-system.svc.cluster.local:9090/config
#api/v1/status/config

## adding workaround to handle ingress cause helm chart doesn't do good job
cat <<EOF | kubectl apply -n kubecost -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubecost-ingress-tls
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "selfsigned-cluster-issuer"
spec:
  ingressClassName: nginx
  rules:
  - host: $(echo ${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN})
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kubecost-cost-analyzer
            port:
              number: 9090
  - host: $(echo ${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN})
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kubecost-cost-analyzer
            port:
              number: 9090
  tls:
  - hosts:
      - $(echo ${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN})
      - $(echo ${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN})
    secretName: kubecost-wildcard-tls
EOF

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=${INSTANCE_NAME}

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

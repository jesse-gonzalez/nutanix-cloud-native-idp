WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm search repo crossplane-stable/crossplane
helm upgrade --install ${INSTANCE_NAME} crossplane-stable/crossplane \
	--namespace ${NAMESPACE} \
	--create-namespace \
	--wait-for-jobs \
	--wait

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=crossplane

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add mongodb https://mongodb.github.io/helm-charts

helm repo update
helm search repo mongodb/enterprise-operator
helm upgrade --install ${INSTANCE_NAME} mongodb/enterprise-operator \
  --set operator.watchNamespace='*' \
	--namespace ${NAMESPACE} \
	--wait-for-jobs \
	--wait

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=mongodb-enterprise-operator --namespace ${NAMESPACE}

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

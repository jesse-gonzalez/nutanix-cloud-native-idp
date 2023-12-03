NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ${INSTANCE_NAME} \
	ingress-nginx/ingress-nginx \
  --version v4.4.2 \
	--set rbac.create=true \
	--set controller.replicaCount=3 \
	--set controller.config.proxy-body-size=0 \
	--set controller.config.proxy-request-buffering=off \
	--set controller.config.proxy-read-timeout=1800 \
	--set controller.config.proxy-send-timeout=1800 \
	--set controller.config.force-ssl-redirect=true \
	--set "controller.extraArgs.enable-ssl-passthrough=" \
	--set ingressClassResource.default=true \
	--namespace=${NAMESPACE} \
	--wait

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

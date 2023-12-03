INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@
NAMESPACE=mongodb-enterprise

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

while [[ -z $(kubectl get svc mongodb-opsmanager-svc-ext -n ${NAMESPACE} -o jsonpath="{.status.loadBalancer.ingress[].ip}" 2>/dev/null) ]]; do
  echo "still waiting for mongodb-opsmanager-svc-ext to have loadbalancer ip"
  sleep 1
done

MONGODB_LOADBALANCER_IP=$(kubectl get svc mongodb-opsmanager-svc-ext -n ${NAMESPACE} -o jsonpath="{.status.loadBalancer.ingress[].ip}")

echo ${MONGODB_LOADBALANCER_IP}

NIPIO_INGRESS_DOMAIN=${MONGODB_LOADBALANCER_IP}.nip.io

echo "nipio_ingress_domain=${NIPIO_INGRESS_DOMAIN}"

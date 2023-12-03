INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

# validate that pre-req have been installed
[ "$(kubectl get po -l app.kubernetes.io/name=cert-manager -o jsonpath='{.items[*].status.phase}' -A | awk '{print $1}')" == "Running" ] || (echo "ERROR: cert-manager not found. cert-mgr, metallb required" && exit 1)
[ "$(kubectl get po -l app.kubernetes.io/name=metallb -o jsonpath='{.items[*].status.phase}' -A | awk '{print $1}')" == "Running" ] || (echo "ERROR: metallb pre-req not found. cert-mgr, metallb required" && exit 1)

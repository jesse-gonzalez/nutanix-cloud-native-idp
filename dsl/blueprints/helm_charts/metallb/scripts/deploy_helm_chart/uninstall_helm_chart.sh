
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}.cfg

# this step will fully delete helm chart and namespaces
kubectl config set-context --current --namespace=${NAMESPACE}
kubectl delete pod --selector=release=${INSTANCE_NAME} --grace-period=0 --force --namespace=${NAMESPACE}
helm uninstall ${INSTANCE_NAME} --namespace=${NAMESPACE}
kubectl delete ns ${NAMESPACE}


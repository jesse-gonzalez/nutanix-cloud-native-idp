NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

# this step will fully delete awx-operator, awx instance, persistent volumes and namespaces
kubectl config set-context --current --namespace=${NAMESPACE}
helm uninstall awx-operator --namespace=awx-operator
kubectl delete pod --selector=release=${INSTANCE_NAME} --grace-period=0 --force --namespace=${NAMESPACE}
kubectl delete pvc --selector=release=${INSTANCE_NAME} --namespace=${NAMESPACE}
kubectl delete ns ${NAMESPACE}

kubectl delete ns --namespace=awx-operator

# cleanup awx crds
kubectl get crd -o name | grep awx | xargs -I {} kubectl delete {}
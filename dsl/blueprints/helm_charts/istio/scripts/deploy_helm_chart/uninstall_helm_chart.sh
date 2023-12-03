
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

if ! kubectl get namespaces -o json | jq -r ".items[].metadata.name" | grep d
then
	echo "Deleting namespace bookinfo"
	kubectl delete namespace bookinfo
fi

# this step will fully delete helm chart and namespaces
kubectl config set-context --current --namespace=${NAMESPACE}

helm delete istio-egress -n ${NAMESPACE}
helm delete istio-ingress -n ${NAMESPACE}
helm delete istiod -n ${NAMESPACE}
helm delete istio-base -n ${NAMESPACE}
kubectl delete ns ${NAMESPACE}

kubectl get crd | grep --color=never 'istio.io' | awk '{print $1}' \
    | xargs -n1 kubectl delete crd

rm ~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg


NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

# this step will fully delete helm chart and namespaces
kubectl config set-context --current --namespace=${NAMESPACE}

# delete all crds from mongodb database instances created by operator, then delete ns...prevents issues with namespaces waiting on finalizers
kubectl get ns -l mongodb.com/instance=true -o name | cut -d/ -f2 | xargs -I {} sh -c "kubectl get mongodb -n {} -o name | xargs -I {cr} kubectl delete {cr} -n {}"
kubectl delete ns -l mongodb.com/instance=true

# remove all customer resource instances before deleting other
kubectl get crds --namespace=${NAMESPACE} | grep mongodb.com | awk '{ print $1 }' | xargs -I {} kubectl get {} -o name --namespace=${NAMESPACE} | xargs -I {} kubectl delete {} --namespace=${NAMESPACE}
kubectl get pod -o name --namespace=${NAMESPACE} | xargs -I {} kubectl delete {} --grace-period=0 --force --namespace=${NAMESPACE} 

helm uninstall ${INSTANCE_NAME} --namespace=${NAMESPACE}
kubectl delete ns ${NAMESPACE}

rm ~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

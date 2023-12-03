
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

# login to cluster
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-port @@{pc_instance_port}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

# //TODO: remove karbon-dnd-infra-cluster hardcoding

# get primary cluster kubeconfig
karbonctl cluster kubeconfig --cluster-name karbon-dnd-infra-cluster > $HOME/karbon-dnd-infra-cluster.cfg
chmod 600 $HOME/karbon-dnd-infra-cluster.cfg

export KUBECONFIG=$KUBECONFIG:$HOME/karbon-dnd-infra-cluster.cfg

export KUBECONFIG=$KUBECONFIG:$HOME/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg
kubectl config use-context ${K8S_CLUSTER_NAME}-context

k10multicluster remove \
    --primary-context=karbon-dnd-infra-cluster-context \
    --primary-name=karbon-dnd-infra-cluster \
    --primary-k10-release-name=k10 \
    --primary-k10-namespace=kasten-io \
    --secondary-context=${K8S_CLUSTER_NAME}-context \
    --secondary-name=${K8S_CLUSTER_NAME} \
    --secondary-k10-namespace=${NAMESPACE}

# this step will fully delete jfrog container registry, persistent volumes and namespaces
kubectl config set-context --current --namespace=${NAMESPACE}
helm uninstall ${INSTANCE_NAME} --namespace=${NAMESPACE}
kubectl delete pod --selector=release=${INSTANCE_NAME} --grace-period=0 --force --namespace=${NAMESPACE}
kubectl delete pvc --selector=release=${INSTANCE_NAME} --namespace=${NAMESPACE}
kubectl delete ns ${NAMESPACE}

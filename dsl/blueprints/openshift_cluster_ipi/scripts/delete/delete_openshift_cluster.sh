OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

## cleanup custom infra machinesets first if needed
## kubectl delete $(kubectl get machineset -o name -n openshift-machine-api | grep infra) -n openshift-machine-api

## run openshift-install destroy cluster
openshift-install destroy cluster --dir $OCP_BUILD_CACHE_BASE

rm -rf $OCP_BUILD_CACHE_BASE
rm -rf .local/$OCP_CLUSTER_NAME
rm -rf $HOME/.kube/$OCP_CLUSTER_NAME.cfg
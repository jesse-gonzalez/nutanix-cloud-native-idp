
INSTANCE_NAME=@@{instance_name}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

monitor_registry_delete_task () {
  echo "Checking Registry Add Status with 5 second intervals"

  build_status=$(./karbonctl cluster tasks list --cluster-name @@{k8s_cluster_name}@@ --output json | jq -r '[ .[] | select( .operation | match("Delete private registry access to k8s")) ]' | jq -r '.[].percent_complete' | tail -n 1)
  echo "Build Status: $build_status percent complete"

  while [ $build_status -lt 100 ];do
      sleep 5
    previous_build_status=$build_status
      build_status=$(./karbonctl cluster tasks list --cluster-name @@{k8s_cluster_name}@@ --output json | jq -r '[ .[] | select( .operation | match("Delete private registry access to k8s")) ]' | jq -r '.[].percent_complete' | tail -n 1)
      if [ -z "${build_status}" ]
    then
      build_status=$previous_build_status
    fi
      echo "Build Status: $build_status percent complete"
  done

}

echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

echo "Get kubeconfig"
karbonctl cluster kubeconfig --cluster-name ${K8S_CLUSTER_NAME} > ~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg
export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

echo ""
echo "Delete docker registry instance secret from all namespaces"
for NS in $(kubectl get ns | cut -d " " -f 1 | tail -n +2 | xargs); do kubectl delete secret ${INSTANCE_NAME}-docker-registry-cred -n $NS; done

echo ""
echo "Remove Docker Registry from the Karbon Kubernetes cluster"
karbonctl cluster registry delete --cluster-name ${K8S_CLUSTER_NAME} --registry-name ${INSTANCE_NAME}_noip
monitor_registry_delete_task

echo ""
echo "List Registered to Cluster"
karbonctl cluster registry list --cluster-name ${K8S_CLUSTER_NAME}

echo ""
echo "Remove Docker Registy to Karbon"
karbonctl registry delete --registry-name ${INSTANCE_NAME}_noip
monitor_registry_delete_task

echo ""
echo "List Registered"
karbonctl registry list


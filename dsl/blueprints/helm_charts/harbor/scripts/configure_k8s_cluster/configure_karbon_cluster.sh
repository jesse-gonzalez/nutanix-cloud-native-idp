
INSTANCE_NAME=@@{instance_name}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@
NAMESPACE=@@{namespace}@@

monitor_registry_add_task () {
  echo "Checking Registry Add Status with 5 second intervals"

  build_status=$(./karbonctl cluster tasks list --cluster-name @@{k8s_cluster_name}@@ --output json | jq -r '[ .[] | select( .operation | match("Add private registry access to k8s")) ]' | jq -r '.[].percent_complete' | tail -n 1)
  echo "Build Status: $build_status percent complete"

  while [ $build_status -lt 100 ];do
      sleep 5
    previous_build_status=$build_status
      build_status=$(./karbonctl cluster tasks list --cluster-name @@{k8s_cluster_name}@@ --output json | jq -r '[ .[] | select( .operation | match("Add private registry access to k8s")) ]' | jq -r '.[].percent_complete' | tail -n 1)
      if [ -z "${build_status}" ]
    then
      build_status=$previous_build_status
    fi
      echo "Build Status: $build_status percent complete"
  done

}

echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

echo ""
echo "Validate DNS on certs"
cat $HOME/.ssh/harbor-ingress_tls.crt | openssl x509 -text -noout | grep DNS
cat $HOME/.ssh/harbor-ingress_ca.crt | openssl x509 -text -noout | grep DNS

echo ""
echo "Register Container Registry to Karbon - noip.io scenario"
karbonctl registry add --name ${INSTANCE_NAME}_noip --url ${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} --cert-file $HOME/.ssh/harbor-ingress_ca.crt --username admin --password @@{Harbor User.secret}@@
monitor_registry_add_task

# echo ""
# echo "Register Container Registry to Karbon - wildcard scenario"
# karbonctl registry add --name ${INSTANCE_NAME}_wildcard --url ${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN} --cert-file $HOME/.ssh/${INSTANCE_NAME}_wildcard_karbon_ca.crt --username admin --password @@{Harbor User.secret}@@
# monitor_registry_add_task

echo ""
echo "List Registered"
karbonctl registry list

echo ""
echo "Register Docker Registy To the Karbon Kubernetes cluster - noip.io scenario"
karbonctl cluster registry add --cluster-name ${K8S_CLUSTER_NAME} --registry-name ${INSTANCE_NAME}_noip
monitor_registry_add_task

# echo ""
# echo "Register Docker Registy To the Karbon Kubernetes cluster - wildcard scenario"
# karbonctl cluster registry add --cluster-name ${K8S_CLUSTER_NAME} --registry-name ${INSTANCE_NAME}_wildcard
# monitor_registry_add_task

echo ""
echo "List Registered to Cluster"
karbonctl cluster registry list --cluster-name ${K8S_CLUSTER_NAME}

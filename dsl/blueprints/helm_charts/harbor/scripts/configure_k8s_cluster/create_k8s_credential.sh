INSTANCE_NAME=@@{instance_name}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@
WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NAMESPACE=@@{namespace}@@

echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

echo "Get kubeconfig"
karbonctl cluster kubeconfig --cluster-name ${K8S_CLUSTER_NAME} > ~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg
export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

echo "Create docker-registry-creds for both noip and wildcard domains"
kubectl create secret docker-registry ${INSTANCE_NAME}-noip-docker-registry-cred --docker-server=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} --docker-username=admin --docker-password='@@{Harbor User.secret}@@' -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry ${INSTANCE_NAME}-wildcard-docker-registry-cred --docker-server=${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN} --docker-username=admin --docker-password='@@{Harbor User.secret}@@' -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo "Get container registry CA and TLS certs for both noip and wildcard domains"
kubectl get secrets harbor-ingress -o jsonpath='{.data.ca\.crt}' -n ${NAMESPACE} | base64 -d > $HOME/.ssh/harbor-ingress_ca.crt
kubectl get secrets harbor-ingress -o jsonpath='{.data.tls\.crt}' -n ${NAMESPACE} | base64 -d > $HOME/.ssh/harbor-ingress_tls.crt

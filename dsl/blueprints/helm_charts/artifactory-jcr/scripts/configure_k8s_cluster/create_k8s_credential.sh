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
kubectl create secret docker-registry ${INSTANCE_NAME}-noip-docker-registry-cred --docker-server=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} --docker-username=admin --docker-password='@@{Artifactory Credential.secret}@@' -n ${NAMESPACE}
kubectl create secret docker-registry ${INSTANCE_NAME}-wildcard-docker-registry-cred --docker-server=${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN} --docker-username=admin --docker-password='@@{Artifactory Credential.secret}@@' -n ${NAMESPACE}

echo "Get artifactory container registry CA and TLS certs for both noip and wildcard domains"
kubectl get secrets ${INSTANCE_NAME}-noip-tls -o jsonpath='{.data.ca\.crt}' -n ${NAMESPACE} | base64 -d > $HOME/.ssh/${INSTANCE_NAME}_noip_karbon_ca.crt
kubectl get secrets ${INSTANCE_NAME}-wildcard-tls -o jsonpath='{.data.ca\.crt}' -n ${NAMESPACE} | base64 -d > $HOME/.ssh/${INSTANCE_NAME}_wildcard_karbon_ca.crt

echo "Create Configmaps with certs"
kubectl -n ${NAMESPACE} create configmap noip-ca-pemstore --from-file=$HOME/.ssh/${INSTANCE_NAME}_noip_karbon_ca.crt
kubectl -n ${NAMESPACE} create configmap wildcard-ca-pemstore --from-file=$HOME/.ssh/${INSTANCE_NAME}_wildcard_karbon_ca.crt


# kubectl get secrets artifactory-jcr-noip-tls -o jsonpath='{.data.ca\.crt}' -n jfrog-container-registry | sudo sh -c 'base64 -d >| /etc/ssl/certs/artifactory-jcr_noip_karbon_ca.crt'
# kubectl get secrets artifactory-jcr-noip-tls -o jsonpath='{.data.tls\.key}' -n jfrog-container-registry | sudo sh -c 'base64 -d >| /etc/ssl/certs/artifactory-jcr_noip_karbon_artifactory_tls.key'
# kubectl get secrets artifactory-jcr-noip-tls -o jsonpath='{.data.tls\.crt}' -n jfrog-container-registry | sudo sh -c 'base64 -d >| /etc/ssl/certs/artifactory-jcr_noip_karbon_artifactory_tls.crt'

# kubectl -n jfrog-container-registry create configmap noip-ca-pemstore --from-file=/etc/ssl/certs/artifactory-jcr_noip_karbon_ca.crt
# kubectl -n jfrog-container-registry create configmap noip-tls-key-pemstore --from-file=/etc/ssl/certs/artifactory-jcr_noip_karbon_artifactory_tls.key
# kubectl -n jfrog-container-registry create configmap noip-tls-cert-pemstore --from-file=/etc/ssl/certs/artifactory-jcr_noip_karbon_artifactory_tls.crt

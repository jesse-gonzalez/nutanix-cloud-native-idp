INSTANCE_NAME=@@{instance_name}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@
NAMESPACE=@@{namespace}@@

echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

echo "Get kubeconfig"
karbonctl cluster kubeconfig --cluster-name ${K8S_CLUSTER_NAME} > ~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg
export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

echo ""
echo "Validate Docker Registry Pull/Push"
# needed to configure insecure registries with self-signed certificates
# get keys and crts from secrets generated by cert-manaager
kubectl config set-context --current --namespace=${NAMESPACE}
kubectl get secrets harbor-ingress -o jsonpath='{.data.ca\.crt}' --namespace=${NAMESPACE} | base64 -d > $HOME/.ssh/harbor-ingress_ca.crt
kubectl get secrets harbor-ingress -o jsonpath='{.data.tls\.key}' --namespace=${NAMESPACE} | base64 -d > $HOME/.ssh/harbor-ingress_tls.key
kubectl get secrets harbor-ingress -o jsonpath='{.data.tls\.crt}' --namespace=${NAMESPACE} | base64 -d > $HOME/.ssh/harbor-ingress_tls.crt

# mv certs to /etc/docker/certs.d directory
sudo mkdir -p /etc/docker/certs.d/${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/;sudo mv $HOME/.ssh/harbor-ingress_tls.crt /etc/docker/certs.d/${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/ca.crt;
# validate that you can login to private registry without having to restart docker
echo '@@{Harbor User.secret}@@' | docker login -u admin ${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} --password-stdin
docker pull hello-world
docker tag hello-world:latest ${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/library/hello-world:latest
docker push ${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/library/hello-world:latest

echo ""
echo "Validate Docker Registry with Karbon Pull"

kubectl create secret docker-registry harbor-docker-registry -n default --docker-server=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} --docker-username=admin --docker-password='@@{Harbor User.secret}@@' --docker-email=no-reply@nutanix.com --dry-run=client -o yaml | kubectl apply -f -

[ "$(kubectl get pods hello-world -n default -o jsonpath='{.metadata.name}')" == "hello-world" ] || (kubectl delete pod hello-world -n default --grace-period=0 --force);
kubectl run -i -t hello-world -n default --restart=Never --rm --image=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/library/hello-world:latest --overrides='{ "apiVersion": "v1", "spec": { "imagePullSecrets": [{"name": "harbor-docker-registry"}] } }';

echo ""
echo "Validate Helm Chart Repository"
helm repo add --ca-file $HOME/.ssh/${INSTANCE_NAME}_karbon_ca.crt harbor-helm https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/library --username admin --password '@@{Harbor User.secret}@@'
helm repo update
helm search repo harbor-helm

## GHOST TEST
# docker pull bitnami/ghost:3.13.2-debian-10-r0
# docker tag docker.io/bitnami/ghost:3.13.2-debian-10-r0 ${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/library/ghost:3.13.2-debian-10-r0
# docker push ${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/library/ghost:3.13.2-debian-10-r0
# helm fetch bitnami/ghost --untar && cd ghost
# edit image.registry and image.repository value
# cd ../ && helm package ./ghost
# curl -kv -uadmin:password -T ghost-12.1.3.tgz "https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/artifactory/helm/ghost-12.1.3.tgz"
# helm install harbor-helm/ghost

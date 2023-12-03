NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# this step will configure helm chart with ingress tls enabled and self-signed certs managed by cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install ${INSTANCE_NAME} jetstack/cert-manager \
	--namespace ${NAMESPACE} \
	--set installCRDs=true \
	--wait

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=cert-manager

echo "Configure Cert-Manager Self-Signed Cluster Issuer"

echo 'apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}' > self-signed-clusterissuer.yaml

# configure default self-signed certificate cluster issuers
kubectl create -f self-signed-clusterissuer.yaml --save-config

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

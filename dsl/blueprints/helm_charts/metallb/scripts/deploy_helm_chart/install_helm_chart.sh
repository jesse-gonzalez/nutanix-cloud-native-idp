K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

METALLB_NET_RANGE=@@{svc_lb_network_range}@@
METALLB_CHART_VERSION=0.13.4

export KUBECONFIG=~/${K8S_CLUSTER_NAME}.cfg

echo "Install MetalLB"
## Create namespace regardless if it exists
kubectl create ns metallb-system -o yaml --dry-run=client | kubectl apply -f -

# Create metallb memberlist secret with layer2 details
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

# install metallb via helm
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm search repo metallb/metallb
helm upgrade --install metallb metallb/metallb \
	--namespace metallb-system \
	--set controller.rbac.create=true	\
  --version=${METALLB_CHART_VERSION} \
	--wait

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=metallb -n metallb-system

## get all metallb validating webhook configurations and failurepolicies
kubectl get validatingwebhookconfigurations metallb-webhook-configuration -o json | jq -r '.webhooks[].name,.webhooks[].failurePolicy'

## patch ipaddresspool validation webhook configuration to ignorepolicy temporarily due to race conditions
kubectl patch validatingwebhookconfigurations metallb-webhook-configuration --patch '{"webhooks": [{"name": "ipaddresspoolvalidationwebhook.metallb.io","failurePolicy": "Ignore"}]}'

## output update
kubectl get validatingwebhookconfigurations metallb-webhook-configuration -o json | jq '.webhooks[] | select(.name == "ipaddresspoolvalidationwebhook.metallb.io")'

## validate that webhook endpoints are available just in case new webhook is introduced that causes failure in later version...
while [[ -z $(kubectl get ep metallb-webhook-service -n metallb-system -o jsonpath='{.subsets[].addresses[]}' 2>/dev/null) ]]; do
  echo "waiting for metallb-webhook-service endpoints to be up and running to avoid internal webhook request failures..."
  sleep 1
done

echo "Configure MetalLB IPAddressPool Custom Resource"

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-metallb-ippool
  namespace: metallb-system
spec:
  addresses:
  - $(echo ${METALLB_NET_RANGE})
EOF

## validate ip pool was created in metallb-system namespace
kubectl get ipaddresspool -n metallb-system -o yaml

## reset ipaddresspool validation webhook configuration to fail if policy not met
kubectl patch validatingwebhookconfigurations metallb-webhook-configuration --patch '{"webhooks": [{"name": "ipaddresspoolvalidationwebhook.metallb.io","failurePolicy": "Fail"}]}'
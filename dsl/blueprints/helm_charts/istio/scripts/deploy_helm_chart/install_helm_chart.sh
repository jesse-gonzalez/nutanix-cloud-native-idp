NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

if ! kubectl get namespaces -o json | jq -r ".items[].metadata.name" | grep ${NAMESPACE}
then
	echo "Creating namespace ${NAMESPACE}"
	kubectl create namespace ${NAMESPACE}
fi

# All binaries, helm charts and sample apps are stored in istio git repo
curl -L https://istio.io/downloadIstio | sh -
cd istio*

# Install the Istio base chart which contains cluster-wide resources used by the Istio control plane
helm upgrade --install istio-base manifests/charts/base \
	--namespace=${NAMESPACE} \
	--set global.jwtPolicy=first-party-jwt \
	--wait

helm status istio-base -n ${NAMESPACE}

# Install the Istio discovery chart which deploys the istiod service
helm upgrade --install istiod manifests/charts/istio-control/istio-discovery \
	--namespace=${NAMESPACE} \
	--set global.jwtPolicy=first-party-jwt \
	--wait

helm status istiod -n ${NAMESPACE}

kubectl wait --for=condition=Ready pod -l app=istiod -n ${NAMESPACE}

# Install the Istio ingress gateway chart which contains the ingress gateway components:
helm upgrade --install istio-ingress manifests/charts/gateways/istio-ingress \
	--namespace=${NAMESPACE} \
	--set global.jwtPolicy=first-party-jwt \
	--wait

helm status istio-ingress -n ${NAMESPACE}

kubectl wait --for=condition=Ready pod -l app=istio-ingressgateway -n ${NAMESPACE}

# I# Install the Istio egress gateway chart which contains the ingress gateway components:
helm upgrade --install istio-egress manifests/charts/gateways/istio-egress \
	--namespace=${NAMESPACE} \
	--set global.jwtPolicy=first-party-jwt \
	--wait

helm status istio-egress -n ${NAMESPACE}

kubectl wait --for=condition=Ready pod -l app=istio-egressgateway -n ${NAMESPACE}

kubectl get pods -n istio-system

NAMESPACE=bookinfo
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

if ! kubectl get namespaces -o json | jq -r ".items[].metadata.name" | grep ${NAMESPACE}
then
	echo "Creating namespace ${NAMESPACE}"
	kubectl create namespace ${NAMESPACE}
fi

# install istioctl cli if it doesn't already exist
[ -f /usr/local/bin/istioctl ] ||
  cd istio*
  sudo cp /usr/local/bin/istioctl .
  sudo chmod +x /usr/local/bin/istioctl

## Add a namespace label to instruct Istio to automatically inject Envoy sidecar proxies when you deploy your application later
kubectl label namespace ${NAMESPACE} istio-injection=enabled

## Deploy the Bookinfo sample application
cd istio*
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml -n ${NAMESPACE}

# validating that all bookinfo components are ready
kubectl wait --for=condition=Ready pod -l app=details -n ${NAMESPACE}
kubectl wait --for=condition=Ready pod -l app=productpage -n ${NAMESPACE}
kubectl wait --for=condition=Ready pod -l app=ratings -n ${NAMESPACE}
kubectl wait --for=condition=Ready pod -l app=reviews -n ${NAMESPACE}

# running quick test
kubectl exec -n ${NAMESPACE} "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

# Open the application to outside traffic
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml -n ${NAMESPACE}

# Ensure that there are no issues with the configuration:
istioctl analyze -n ${NAMESPACE} -v

# Determining the ingress IP and ports
kubectl get svc istio-ingressgateway -n istio-system

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo "INGRESS_HOST=`echo $INGRESS_HOST`"
echo "INGRESS_PORT=`echo $INGRESS_PORT`"
echo "SECURE_INGRESS_PORT=`echo $SECURE_INGRESS_PORT`"
echo "GATEWAY_URL=`echo $GATEWAY_URL`"

echo "Access BookInfo Page by accessing - http://`echo $GATEWAY_URL`/productpage"

# view Kiali dashboard
kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system

echo "Access Dasbhoard by running - istioctl dashboard kiali"

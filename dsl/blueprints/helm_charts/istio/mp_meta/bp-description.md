
#### Connectivity Details

Access Istio `Kiali` Dasbhoard:

`istioctl dashboard kiali` [will launch browser]

#### After Running Day 2 Action - `Deploy Istio Demo App`

Access `BookInfo` Page by accessing:

```
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
```

`http://$GATEWAY_URL:80/productpage`
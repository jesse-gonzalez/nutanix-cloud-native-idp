#!/bin/bash
set -e
set -o pipefail

K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-port @@{pc_instance_port}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

echo "Set KUBECONFIG"
karbonctl cluster kubeconfig --cluster-name ${K8S_CLUSTER_NAME} > ~/${K8S_CLUSTER_NAME}.cfg

export KUBECONFIG=~/${K8S_CLUSTER_NAME}.cfg

echo "Install MetalLB"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml

# On first install only
#kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"


while [[ -z $(kubectl get deploy controller -n metallb-system 2>/dev/null) ]]; do
  echo "Waiting for MetalLB deployments to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=5m -n metallb-system $(kubectl get deploy controller -n metallb-system -o name)

## configure ipaddresspool custom resource instance

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - @@{svc_lb_network_range}@@
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF

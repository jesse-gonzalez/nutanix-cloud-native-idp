#!/bin/bash
set -e
set -o pipefail

K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

echo "Login karbonctl"
karbonctl login --pc-ip @@{pc_instance_ip}@@ --pc-port @@{pc_instance_port}@@ --pc-username @@{Prism Central User.username}@@ --pc-password @@{Prism Central User.secret}@@

echo "Set KUBECONFIG"
karbonctl cluster kubeconfig --cluster-name ${K8S_CLUSTER_NAME} > ~/${K8S_CLUSTER_NAME}.cfg

export KUBECONFIG=~/${K8S_CLUSTER_NAME}.cfg

# install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -n kube-system
#kubectl -n kube-system patch deployment metrics-server --type='json' -p '[{"op": "replace","path": "/spec/template/spec/containers/0/args","value": ["--cert-dir=/tmp","--secure-port=443","--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname","--kubelet-use-node-status-port","--kubelet-insecure-tls"]}]'

# wait for metrics server pod to be ready
sleep 30s
kubectl wait -n kube-system --for=condition=Ready po -l k8s-app=metrics-server --timeout=300s


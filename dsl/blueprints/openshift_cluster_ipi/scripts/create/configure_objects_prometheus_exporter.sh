#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
NTNX_PC_USER=@@{Prism Central User.username}@@
NTNX_PC_PASS=@@{Prism Central User.secret}@@

NTNX_PC_FQDN=@@{ocp_ntnx_pc_dns_fqdn}@@
NTNX_PC_IP=@@{pc_instance_ip}@@

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## enable User-Workload Monitoring Stack
## Create new Project/Namespace

kubectl create ns external-service --dry-run=client -o yaml | kubectl apply -f -

## Create Secret with PC Credentials

kubectl create secret -n external-service generic pc-creds --from-literal=user=$NTNX_PC_USER --from-literal=password=$NTNX_PC_PASS --dry-run=client -o yaml | kubectl apply -f -

## Create Endpoint (Prism Central IP)
cat << EOF | kubectl apply -f -
kind: "Endpoints"
apiVersion: "v1"
metadata:
  name: "external-nutanix-objects"
  namespace: external-service
subsets:
  - addresses:
      - ip: $NTNX_PC_IP 
    ports:
      - port: 9440 
        name: "objects-metrics"
EOF

kubectl get ep external-nutanix-objects -n external-service

## Create Service

cat << EOF | kubectl apply -f -
kind: "Service"
apiVersion: "v1"
metadata:
  labels:
    external-infra-monitor: "true"
  name: "external-nutanix-objects"
  namespace: external-service
spec:
  ports:
    - name: "objects-metrics"
      protocol: "TCP"
      port: 9440
      targetPort: 9440 
      nodePort: 0
EOF

kubectl get svc external-nutanix-objects -n external-service

## Create ServiceMonitor (for Statistics and Performance on Objects-Store Level)

cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nutanix-objects-store
  namespace: external-service
spec:
  endpoints:
  - interval: 30s
    basicAuth:
      password:
        name: pc-creds
        key: password
      username:
        name: pc-creds
        key: user
    path: /oss/api/nutanix/metrics
    port: objects-metrics
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
  selector:
    matchLabels:
      external-infra-monitor: "true"
EOF

## Create ServiceMonitor (for Statistics and Performance on dedicated Bucket) - targeting oadp

cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nutanix-objects-oadp
  namespace: external-service
spec:
  endpoints:
  - interval: 30s
    basicAuth:
      password:
        name: pc-creds
        key: password
      username:
        name: pc-creds
        key: user
    path: /oss/api/nutanix/metrics/ntnx-objects/oadp
    port: objects-metrics
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
  selector:
    matchLabels:
      external-infra-monitor: "true"
EOF

## Create ServiceMonitor (for Statistics and Performance on dedicated Bucket) - targeting image-registry-bucket

cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nutanix-objects-image-registry-bucket
  namespace: external-service
spec:
  endpoints:
  - interval: 30s
    basicAuth:
      password:
        name: pc-creds
        key: password
      username:
        name: pc-creds
        key: user
    path: /oss/api/nutanix/metrics/ntnx-objects/image-registry-bucket
    port: objects-metrics
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
  selector:
    matchLabels:
      external-infra-monitor: "true"
EOF

## Create ServiceMonitor (for Statistics and Performance on dedicated Bucket) - targeting thanos

cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nutanix-objects-thanos
  namespace: external-service
spec:
  endpoints:
  - interval: 30s
    basicAuth:
      password:
        name: pc-creds
        key: password
      username:
        name: pc-creds
        key: user
    path: /oss/api/nutanix/metrics/ntnx-objects/thanos
    port: objects-metrics
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
  selector:
    matchLabels:
      external-infra-monitor: "true"
EOF

## Create ServiceMonitor (for Statistics and Performance on dedicated Bucket) - targeting quay

cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nutanix-objects-quay
  namespace: external-service
spec:
  endpoints:
  - interval: 30s
    basicAuth:
      password:
        name: pc-creds
        key: password
      username:
        name: pc-creds
        key: user
    path: /oss/api/nutanix/metrics/ntnx-objects/quay
    port: objects-metrics
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
  selector:
    matchLabels:
      external-infra-monitor: "true"
EOF

## validate
kubectl get svc,ep,servicemonitor -n external-service

## Now you are able to collect Metrics from OpenShift Dashboard, accessing Observe → Metrics → Search for 'nutanix_objectstore'


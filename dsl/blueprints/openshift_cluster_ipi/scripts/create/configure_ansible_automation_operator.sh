#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

OPERATOR_NS=ansible-automation-platform
OPERATOR_NAME=ansible-automation-platform-operator
OPERATOR_CHANNEL=stable-2.4-cluster-scoped

ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT=@@{enable_redhat_advanced_cluster_management}@@

if [[ "${ENABLE_REDHAT_ADVANCED_CLUSTER_MGMT}" == "true" ]]
then

## kubectl create operator namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: $OPERATOR_NS
EOF

## kubectl create operatorgroup
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: $OPERATOR_NAME-opgroup
  namespace: $OPERATOR_NS
spec:
  targetNamespaces:
  - $OPERATOR_NS
EOF

kubectl get operatorgroup -n $OPERATOR_NS

## get options: kubectl get packagemanifests ansible-automation-platform-operator -n openshift-marketplace
## kubectl install operator from openshift-marketplace
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $OPERATOR_NAME
  namespace: $OPERATOR_NS
spec:
  config:
    tolerations:
    - key: "node-role.kubernetes.io/infra"
      operator: "Exists"
      value: ""
      effect: "NoSchedule"
  channel: $OPERATOR_CHANNEL
  name: $OPERATOR_NAME
  installPlanApproval: Automatic
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

while [[ -z $(kubectl get deployment -l olm.owner.namespace=$OPERATOR_NS -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for Ansible Automation Platform Operator deployments to be created..."
  sleep 30
done

kubectl wait --for=condition=available --timeout=10m -n $OPERATOR_NS $(kubectl get deployment -n $OPERATOR_NS -o name)


## Configure Ansible Automation Controller
cat <<EOF | kubectl apply -f -
apiVersion: automationcontroller.ansible.com/v1beta1
kind: AutomationController
metadata:
  name: aap-automation-controller
  namespace: $OPERATOR_NS
spec:
  postgres_keepalives_count: 5
  postgres_keepalives_idle: 5
  create_preload_data: true
  route_tls_termination_mechanism: Edge
  garbage_collect_secrets: false
  ingress_type: Route
  loadbalancer_port: 80
  no_log: true
  image_pull_policy: IfNotPresent
  projects_storage_class: nutanix-dynamicfile
  projects_storage_size: 8Gi
  projects_storage_access_mode: ReadWriteMany
  auto_upgrade: true
  task_privileged: false
  postgres_keepalives: true
  postgres_keepalives_interval: 5
  ipv6_disabled: false
  set_self_labels: true
  projects_persistence: true
  replicas: 1
  admin_user: admin
  route_host: aap-automation-controller-aap.apps.$OCP_CLUSTER_NAME.$OCP_BASE_DOMAIN
  loadbalancer_protocol: http
EOF


while [[ -z $(kubectl get deployment -l app.kubernetes.io/component=automationcontroller -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for Ansible Automation Controller deployments to be created..."
  sleep 30
done

kubectl wait --for=condition=available --timeout=10m -n $OPERATOR_NS $(kubectl get deployment -l app.kubernetes.io/component=automationcontroller -n $OPERATOR_NS -o name)

## validate connectivity
kubectl get secret/aap-automation-controller-admin-password -o jsonpath='{.data.password}' -n $OPERATOR_NS | base64 -d
kubectl get route aap-automation-controller -n $OPERATOR_NS

## Configure Ansible AutomationHub
cat <<EOF | kubectl apply -f -
apiVersion: automationhub.ansible.com/v1beta1
kind: AutomationHub
metadata:
  name: aap-hub
  namespace: $OPERATOR_NS
spec:
  nginx_proxy_send_timeout: 120s
  gunicorn_content_workers: 2
  gunicorn_api_workers: 2
  route_tls_termination_mechanism: Edge
  ingress_type: Route
  loadbalancer_port: 80
  no_log: true
  storage_type: File
  file_storage_storage_class: nutanix-dynamicfile
  file_storage_size: 100Gi
  image_pull_policy: IfNotPresent
  nginx_proxy_read_timeout: 120s
  gunicorn_timeout: 90
  nginx_client_max_body_size: 10m
  web:
    replicas: 1
  nginx_proxy_connect_timeout: 120s
  haproxy_timeout: 180s
  file_storage_access_mode: ReadWriteMany
  content:
    log_level: INFO
    replicas: 2
  postgres_storage_requirements:
    limits:
      storage: 50Gi
    requests:
      storage: 8Gi
  api:
    log_level: INFO
    replicas: 1
  postgres_resource_requirements:
    limits:
      cpu: 1000m
      memory: 8Gi
    requests:
      cpu: 500m
      memory: 2Gi
  redis:
    log_level: INFO
    replicas: 1
  loadbalancer_protocol: http
  resource_manager:
    replicas: 1
  worker:
    replicas: 2
  route_host: aap-hub.apps.$OCP_CLUSTER_NAME.$OCP_BASE_DOMAIN
  postgres_storage_class: nutanix-volume
  pulp_settings:
    galaxy_collection_signing_service: ''
    galaxy_container_signing_service: ''
EOF

while [[ -z $(kubectl get deployments -l app.kubernetes.io/part-of=automationhub -n $OPERATOR_NS 2>/dev/null) ]]; do
  echo "Waiting for Ansible Automation Hub deployments to be created..."
  sleep 30
done

kubectl wait --for=condition=available --timeout=20m -n $OPERATOR_NS $(kubectl get deployment.apps/aap-hub-redis -n $OPERATOR_NS -o name)
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=20m -n $OPERATOR_NS $(kubectl get deployment.apps/aap-hub-api -n $OPERATOR_NS -o name) || kubectl rollout restart deployment.apps/aap-hub-api -n $OPERATOR_NS && kubectl rollout status deployment.apps/aap-hub-api -n $OPERATOR_NS
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=20m -n $OPERATOR_NS $(kubectl get deployment.apps/aap-hub-content -n $OPERATOR_NS -o name) || kubectl rollout restart deployment.apps/aap-hub-content -n $OPERATOR_NS && kubectl rollout status deployment.apps/aap-hub-content -n $OPERATOR_NS
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=available --timeout=20m -n $OPERATOR_NS $(kubectl get deployment.apps/aap-hub-worker -n $OPERATOR_NS -o name) || kubectl rollout restart deployment.apps/aap-hub-worker -n $OPERATOR_NS && kubectl rollout status deployment.apps/aap-hub-worker -n $OPERATOR_NS
sleep 10s ## to handle api server disconnect failures, needs further investigation

## Validate Connectivity
kubectl get route aap-hub -n $OPERATOR_NS
kubectl get secret aap-hub-admin-password -o jsonpath='{.data.password}' -n $OPERATOR_NS | base64 -d

fi

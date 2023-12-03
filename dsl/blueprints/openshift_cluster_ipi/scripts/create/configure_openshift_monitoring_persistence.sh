#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

## https://portal.nutanix.com/page/documents/solutions/details?targetId=TN-2030-Red-Hat-OpenShift-on-Nutanix:red-hat-openshift-monitoring.html
## update openshift monitoring configmaps
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true
    alertmanagerMain:
      volumeClaimTemplate:
        spec:
          storageClassName: nutanix-volume
          resources:
            requests:
              storage: 20Gi
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusK8s:
      retention: 15d
      volumeClaimTemplate:
        spec:
          storageClassName: nutanix-volume
          resources:
            requests:
              storage: 2000Gi
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusOperator:
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    grafana:
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    k8sPrometheusAdapter:
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    kubeStateMetrics:
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
    telemeterClient:
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    openshiftStateMetrics:
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
    thanosQuerier:
      tolerations:
      - key: "node-role.kubernetes.io/infra"
        operator: "Exists"
        value: ""
        effect: "NoSchedule"
      nodeSelector:
        node-role.kubernetes.io/infra: ""
EOF

## wait for alertmanager and prometheus-k8s to be updated
kubectl wait --for=condition=Ready --timeout=15m pods -l alertmanager=main -n openshift-monitoring
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl wait --for=condition=Ready --timeout=15m pods -l prometheus=k8s -n openshift-monitoring
sleep 10s ## to handle api server disconnect failures, needs further investigation

## validate po and pvcs created successfully
kubectl get statefulset,pvc -n openshift-monitoring

## this should have also configured user workload monitoring

#kubectl wait --for=condition=Ready --timeout=15m pods -l app.kubernetes.io/instance=user-workload -n openshift-user-workload-monitoring

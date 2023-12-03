OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

OCP_INFRA_NODE_REPLICA_COUNT=@@{infra_machineset_count}@@

NTNX_PROJECT_UUID=@@{project_uuid}@@

## create infra-user-data secret vs. using worker-user-data
kubectl get secret worker-user-data -n openshift-machine-api -o json | sed 's/worker-user-data/infra-user-data/g' | kubectl apply -n openshift-machine-api -f -

## one liner to create machineset from existing worker machineset
#kubectl get $(kubectl get machineset -n openshift-machine-api --output=name) -n openshift-machine-api -o json | sed 's/worker/infra/g' | jq '.spec.template.spec +={"metadata":{"labels":{"node-role.kubernetes.io/infra":""}},"taints":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/infra"}]}' | kubectl apply -n openshift-machine-api -f -

MACHINESET_CLUSTER_ID=$(kubectl get machineset -n openshift-machine-api | grep worker | cut -d' ' -f 1 | sed 's/-worker//g')

NTNX_PE_CLUSTER_UUID=@@{prism_element_uuid}@@
NTNX_PE_NETWORK_UUID=@@{network_uuid}@@

cat <<EOF | kubectl apply -f -
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: $MACHINESET_CLUSTER_ID
  name: $MACHINESET_CLUSTER_ID-infra
  namespace: openshift-machine-api
spec:
  deletePolicy: Oldest
  replicas: $OCP_INFRA_NODE_REPLICA_COUNT
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: $MACHINESET_CLUSTER_ID
      machine.openshift.io/cluster-api-machineset: $MACHINESET_CLUSTER_ID-infra
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: $MACHINESET_CLUSTER_ID
        machine.openshift.io/cluster-api-machine-role: infra
        machine.openshift.io/cluster-api-machine-type: infra
        machine.openshift.io/cluster-api-machineset: $MACHINESET_CLUSTER_ID-infra
    spec:
      lifecycleHooks: {}
      metadata:
        labels:
          node-role.kubernetes.io/infra: ""
      providerSpec:
        value:
          apiVersion: machine.openshift.io/v1
          bootType: Legacy
          categories:
          - key: AppType
            value: KubernetesInfra
          cluster:
            type: uuid
            uuid: $NTNX_PE_CLUSTER_UUID
          credentialsSecret:
            name: nutanix-credentials
          image:
            name: $MACHINESET_CLUSTER_ID-rhcos
            type: name
          kind: NutanixMachineProviderConfig
          memorySize: 24Gi
          metadata:
            creationTimestamp: null
          project:
            type: uuid
            uuid: $NTNX_PROJECT_UUID
          subnets:
          - type: uuid
            uuid: $NTNX_PE_NETWORK_UUID
          systemDiskSize: 200Gi
          userDataSecret:
            name: infra-user-data
          vcpuSockets: 4
          vcpusPerSocket: 2
EOF

## scale cluster to expected count
kubectl scale --replicas=$OCP_INFRA_NODE_REPLICA_COUNT $(kubectl get machineset -n openshift-machine-api --output=name | grep infra) -n openshift-machine-api

## To change VM Specs on any available MachineSet. Reconcile does not respect CPU/RAM right now, it is needed to change deletePolicy and scaleup/down
## kubectl patch -n openshift-machine-api $(kubectl get machineset -n openshift-machine-api --output=name) --type merge --patch '{"spec":{"deletePolicy": "Oldest"}}'

## wait for infra nodes to be ready

while [[ -z $(kubectl get machine -l machine.openshift.io/cluster-api-machine-type=infra -n openshift-machine-api 2>/dev/null) ]]; do
  echo "Waiting for infra machines to be created..."
  sleep 30
done

kubectl wait --for=jsonpath='{.status.phase}'=Running machine --timeout=20m -l machine.openshift.io/cluster-api-machine-type=infra -n openshift-machine-api
sleep 10s ## to handle api server disconnect failures, needs further investigation

while [[ -z $(kubectl get node -l node-role.kubernetes.io/infra= 2>/dev/null) ]]; do
  echo "Waiting for infra nodes to be ready..."
  sleep 30
done

kubectl wait --for=condition=Ready node --timeout=20m -l node-role.kubernetes.io/infra=
sleep 10s ## to handle api server disconnect failures, needs further investigation

## validate
kubectl get machines,nodes -o wide

## configure taints on infra nodes
kubectl taint node -l node-role.kubernetes.io/infra node-role.kubernetes.io/infra:NoSchedule

## make sure all infra nodes are available
kubectl get node -l node-role.kubernetes.io/infra= -o name | xargs kubectl uncordon

## migrate workloads to infra nodes
kubectl patch ingresscontroller default -n openshift-ingress-operator --type merge --patch '{"spec":{"nodePlacement":{"nodeSelector":{"matchLabels":{"node-role.kubernetes.io/infra":""}},"tolerations":[{"effect":"NoSchedule","operator":"Exists"}]}}}'
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec": {"nodeSelector": {"node-role.kubernetes.io/infra": ""},"affinity": {"podAntiAffinity": {"preferredDuringSchedulingIgnoredDuringExecution": [{"podAffinityTerm": {"namespaces": ["openshift-image-registry"],"topologyKey": "kubernetes.io/hostname"},"weight": 100}]}},"logLevel": "Normal"}}'
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"tolerations":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/infra","operator":"Exists"}]}}'


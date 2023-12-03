set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

# OCP_CLUSTER_NAME=kalm-main-20-4-ocp

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

cat <<EOF | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  generateName: demo-job-
spec:
  template:
    spec:
      containers:
      - name: work
        image: quay.io/quay/busybox
        command: ["sleep",  "480"]
        resources:
          requests:
            memory: 500Mi
            cpu: 500m
      restartPolicy: Never
  backoffLimit: 4
  completions: 50
  parallelism: 50
EOF

## If we wait for a minute and check the pod status, we would see a huge number of pods running.

oc get pod -n autoscale-example

oc get machines -n openshift-machine-api

## After eight minutes, the workload starts to terminate and the load on the cluster reduces. We can now see that the machine autoscaler will begin to delete the unnecessary Machines from the MachineSet.






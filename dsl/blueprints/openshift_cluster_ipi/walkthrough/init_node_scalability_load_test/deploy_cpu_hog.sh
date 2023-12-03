
OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

# create kubectl stress namespace if it doesn't exist
kubectl create namespace stress --dry-run=client -o yaml | kubectl apply -f -

# configure hog yaml file based on inputs
# this will create a single pod and allocate max of 1 CPU (1000m), about 50% of what is current limit
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app: hog
  name: hog
  namespace: stress
spec:
  selector:
    matchLabels:
      app: hog
  template:
    metadata:
      labels:
        app: hog
    spec:
      containers:
      - image: vish/stress
        name: stress
        resources:
          requests:
            cpu: "0.5"
        args:
        - -cpus
        - "6"
EOF

# wait for hog pods to be ready
kubectl wait --for=condition=Ready ds hog -n stress 

# watch progress of hpa, nodes, pods in one screen
# watch -n .5 "kubectl top nodes && echo "" && kubectl top pods && echo "" && kubectl get hpa,ds,po -o wide"

# watch events in other
# kubectl get events

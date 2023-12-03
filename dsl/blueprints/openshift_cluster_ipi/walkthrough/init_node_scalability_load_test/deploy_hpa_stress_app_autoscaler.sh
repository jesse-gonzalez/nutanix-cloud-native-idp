OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

# create kubectl stress namespace if it doesn't exist
kubectl create namespace stress --dry-run=client -o yaml | kubectl apply -f -

# configure hog yaml file based on inputs
## based off of https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
## This is a custom docker images that has simple index.php page which performs some CPU intensive computations:

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  replicas: 1
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    run: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache
EOF

# validate php-apache deployment
kubectl get deployment php-apache -o yaml -n stress

# wait for php-apache pods to be ready
kubectl wait --for=condition=Ready pod/$(kubectl get po -l run=php-apache -n stress -o jsonpath='{.items[].metadata.name}')

# deploy horizontal autoscaler and label
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10 -n stress
kubectl label hpa php-apache run=php-apache -n stress

# validate hpa
kubectl get hpa php-apache -o yaml -n stress

# generate load using alternative container. Open 3 terminals

# watch events in first terminal
# kubectl get events -w

# generate load.
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"


# monitor progress of hpa, nodes, deployments, pods & svc in one screen.
## you'll see initial current metric percentage at somewhere between 250 - 305% higher than the target 50%.
# watch -n .5 "kubectl top nodes && echo "" && kubectl top pods && echo "" && kubectl get hpa,deploy,po,svc -o wide"


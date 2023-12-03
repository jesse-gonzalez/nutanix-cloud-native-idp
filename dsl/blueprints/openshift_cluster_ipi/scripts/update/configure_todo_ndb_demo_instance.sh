#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

ERA_VM_IP=@@{era_vm_ip}@@
ERA_CLUSTER_UUID=@@{era_cluster_uuid}@@
ERA_USER='@@{Era User.username}@@'
ERA_PASS='@@{Era User.secret}@@'
NTNX_PUBLIC_SSH_KEY="@@{nutanix_public_key}@@"

NAMESPACE=todo

RANDOM_ID=$RANDOM

POSTGRESQL_NDB_SERVER_NAME="todo-demo-$RANDOM_ID"
POSTGRESQL_INSTANCE_NAME='todo-db'
POSTGRESQL_USER='postgres'
POSTGRESQL_PASSWORD='todoPassword'
POSTGRESQL_DATABASE='todo'

## configure namespace where ndb operator - database custom resource will live
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

## configure ndb instance connectivity info
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: v1
kind: Secret
metadata:
  name: era-ndb-secret
type: Opaque
stringData:
  username: ${ERA_USER}
  password: ${ERA_PASS}
EOF

## create ndb database operator - custom resource instance 
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${POSTGRESQL_DATABASE}-secret
type: Opaque
stringData:
  password: ${POSTGRESQL_PASSWORD}
  ssh_public_key: |
    ${NTNX_PUBLIC_SSH_KEY}
---
apiVersion: ndb.nutanix.com/v1alpha1
kind: Database
metadata:
  name: ${POSTGRESQL_INSTANCE_NAME}
spec:
  ndb:
    clusterId: $ERA_CLUSTER_UUID
    server: https://$ERA_VM_IP:8443/era/v0.9
    credentialSecret: era-ndb-secret
    skipCertificateVerification: true
  databaseInstance:
    databaseInstanceName: ${POSTGRESQL_NDB_SERVER_NAME}
    databaseNames:
      - ${POSTGRESQL_DATABASE}
    credentialSecret: ${POSTGRESQL_DATABASE}-secret
    size: 500
    timezone: "UTC"
    type: postgres
EOF

## validate
while [[ -z $(kubectl get database ${POSTGRESQL_INSTANCE_NAME} -n $NAMESPACE 2>/dev/null) ]]; do
  echo "Waiting for ${POSTGRESQL_INSTANCE_NAME} custom resource to be created..."
  sleep 60
done

## wait for instance to be complete
sleep 60s
kubectl wait --for=jsonpath='{.status.status}'=READY --timeout=60m database ${POSTGRESQL_INSTANCE_NAME} -n $NAMESPACE
sleep 10s ## to handle api server disconnect failures, needs further investigation

## validate from kubectl
kubectl describe database ${POSTGRESQL_INSTANCE_NAME} -n $NAMESPACE
kubectl get svc,ep ${POSTGRESQL_INSTANCE_NAME}-svc -n $NAMESPACE

## validate connectivity
kubectl run --restart=Never psql-$RANDOM_ID -n $NAMESPACE --image=quay.io/coreos/postgres --env=POSTGRESQL_SVC=${POSTGRESQL_INSTANCE_NAME}-svc --env=POSTGRESQL_PASSWORD=$POSTGRESQL_PASSWORD --env=POSTGRESQL_USER=$POSTGRESQL_USER --env=POSTGRESQL_DATABASE=$POSTGRESQL_DATABASE

while [[ -z $(kubectl get pod psql-$RANDOM_ID -n $NAMESPACE 2>/dev/null) ]]; do
  echo "Waiting for postgresql client util pod to be created..."
  sleep 15
done

kubectl wait --for=condition=Ready --timeout=5m -n $NAMESPACE pod psql-$RANDOM_ID
sleep 10s ## to handle api server disconnect failures, needs further investigation
kubectl exec -i psql-$RANDOM_ID -n $NAMESPACE -- sh -c 'echo "\du" | PGPASSWORD=$POSTGRESQL_PASSWORD psql -h $POSTGRESQL_SVC -p 80 $POSTGRESQL_DATABASE $POSTGRESQL_USER'

## deploy todo app
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: todo
    app.kubernetes.io/component: todo
    app.kubernetes.io/instance: todo
    app.kubernetes.io/name: java
    app.kubernetes.io/part-of: todo-app
    app.openshift.io/runtime: quarkus
    app.openshift.io/runtime-version: 2.7.5.Final
  name: todo
  namespace: todo
spec:
  selector:
    matchLabels:
      app: todo
  template:
    metadata:
      labels:
        app: todo
        version: v1
        maistra.io/expose-route: 'true'
    spec:
      containers:
      - name: todo
        image: quay.io/voravitl/todo:native
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          protocol: TCP
        resources:
          requests:
            cpu: "0.05"
            memory: 40Mi
          limits:
            cpu: "0.1"
            memory: 200Mi
        env:
        - name: quarkus.http.access-log.enabled
          value: "false"
        - name: quarkus.datasource.username
          value: ${POSTGRESQL_USER}
        - name: quarkus.datasource.password
          value: ${POSTGRESQL_PASSWORD}
        - name: quarkus.datasource.jdbc.url
          value: "jdbc:postgresql://${POSTGRESQL_INSTANCE_NAME}-svc:80/todo"
        readinessProbe:
          httpGet:
            path: /q/health/ready
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 120 
        livenessProbe:
          httpGet:
            path: /q/health/live
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 180             
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          capabilities:
            drop: ["ALL"]
          seccompProfile:
            type: RuntimeDefault
          readOnlyRootFilesystem: false
---
apiVersion: v1
kind: Service
metadata:
  name: todo
  namespace: todo
  labels:
    app: todo
  annotations:
    argocd.argoproj.io/hook: Sync
    argocd.argoproj.io/sync-wave: "2"
spec:
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: todo
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: todo
  namespace: todo
  labels:
    app: todo
spec:
  port:
    targetPort: http
  tls:
    termination: edge
  to:
    kind: Service
    name: todo
    weight: 100
  wildcardPolicy: None
EOF

while [[ -z $(kubectl get deploy todo -n $NAMESPACE 2>/dev/null) ]]; do
  echo "Waiting for todo app deployment to be created..."
  sleep 15
done

kubectl wait --for=condition=available --timeout=10m deployment todo -n $NAMESPACE

## configure servicemonitor
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: todo
  namespace: todo
  labels:
    app: todo
spec:
  endpoints:
  - interval: 60s
    port: http
    path: /q/metrics
    scheme: http
    targetPort: 8080
  - interval: 60s
    port: http
    path: /q/metrics/application
    scheme: http
    targetPort: 8080
  selector:
    matchLabels:
      app: todo
EOF

## final validation
kubectl get po,database,svc,route,servicemonitor -n $NAMESPACE

echo -e "\nTODO Application URL: https://$(kubectl get route todo -n $NAMESPACE -o jsonpath='{.spec.host}')"
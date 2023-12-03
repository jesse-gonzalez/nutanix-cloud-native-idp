

DOCKER_HUB_USER=@@{Docker Hub User.username}@@
DOCKER_HUB_PASS=@@{Docker Hub User.secret}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

# create dockerhub registry secret used to get around docker hub pull rate limitations. It will be configured on default namespace then synchronized.
kubectl create secret docker-registry image-pull-secret --docker-username=${DOCKER_HUB_USER} --docker-password=${DOCKER_HUB_PASS} -n default --dry-run=client -o yaml | kubectl apply -f -

# https://devopstales.github.io/kubernetes/k8s-imagepullsecret-patcher/
# configure kyverno cluster policy to effectively mutate container images to include the imagepull secret name and continuously synchronize docker registry secret across namespaces
cat <<EOF | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: sync-secret
spec:
  background: false
  rules:
  - name: sync-image-pull-secret
    exclude:
      any:
        - resources:
            names:
            - "kube-system"
            - "ntnx-system"
            kinds:
            - Namespace
            selector:
              matchExpressions:
                - {key: field.cattle.io/projectId, operator: Exists}
    match:
      any:
      - resources:
          kinds:
          - Namespace
    generate:
      kind: Secret
      name: image-pull-secret
      namespace: "{{request.object.metadata.name}}"
      synchronize: true
      clone:
        namespace: default
        name: image-pull-secret
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: mutate-imagepullsecret
spec:
  background: true
  rules:
    - name: mutate-imagepullsecret
      match:
        any:
        - resources:
            kinds:
            - Pod
            - Deployment
      exclude:
        any:
        - resources:
            names:
            - "kube-system"
            - "ntnx-system"
            kinds:
            - Namespace
            selector:
              matchExpressions:
                - {key: field.cattle.io/projectId, operator: Exists}
      preconditions:
        any:
        - key: "ghcr.io"          
          operator: NotIn
          value: "{{ images.*.registry }}"
        - key: "quay.io"          
          operator: NotIn
          value: "{{ images.*.registry }}"
        - key: "*"
          operator: In
          value: "{{ images.initContainers.*.registry }}"
      mutate:
        patchStrategicMerge:
          spec:
            imagePullSecrets:
            - name: image-pull-secret  ## imagePullSecret that you created with docker hub pro account
EOF

## adding these steps due to kyverno issues

## https://kyverno.io/docs/troubleshooting/

kubectl delete validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg
kubectl delete  mutatingwebhookconfiguration kyverno-resource-mutating-webhook-cfg

kubectl scale deploy kyverno -n kyverno --replicas 0
kubectl scale deploy kyverno -n kyverno --replicas 3
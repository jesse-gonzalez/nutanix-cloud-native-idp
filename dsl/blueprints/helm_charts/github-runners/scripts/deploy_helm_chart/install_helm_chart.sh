NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

#GITHUB_CONFIG_URL="https://github.com/jesse-gonzalez/cloud-native-calm"
GITHUB_CONFIG_URL="@@{github_repo_url}@@"
GITHUB_PAT=@@{GitHub User.secret}@@

## install github actions runner controller and scale set
helm upgrade --install actions-runner-controller \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
    --wait

helm status actions-runner-controller -n ${NAMESPACE}

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=actions-runner-controller

helm upgrade --install actions-runner-set \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
    --set containerMode.type=dind \
    --wait


    --set containerMode.kubernetesModeWorkVolumeClaim.storageClassName=default-storageclass \

helm status actions-runner-set -n ${NAMESPACE}

NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

#GITHUB_REPO_URL="https://github.com/jesse-gonzalez/nutanix-cloud-native-idp.git"
GITHUB_REPO_URL="@@{github_repo_url}@@"

GITHUB_REPO_URL_WO_SUFFIX="${GITHUB_REPO_URL%.*}"
GITHUB_REPO_ORG="$(basename "${GITHUB_REPO_URL_WO_SUFFIX}")"
GITHUB_REPO_NAME="$(basename "${GITHUB_REPO_URL_WO_SUFFIX%/${GITHUB_REPO_ORG}}")"
GITHUB_REPO_SLUG="$GITHUB_REPO_NAME/$GITHUB_REPO_ORG"

GITHUB_CONFIG_URL=$GITHUB_REPO_URL_WO_SUFFIX

echo $GITHUB_CONFIG_URL

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

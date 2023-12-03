TARGET_NS=kasten-io
kubectl create secret docker-registry image-pull-secret --docker-username=${DOCKER_HUB_USER} --docker-password=${DOCKER_HUB_PASS} -n ${TARGET_NS} --dry-run=client -o yaml | kubectl apply -f -
kubectl get serviceaccount -o name -n ${TARGET_NS} | xargs -I {} sh -c 'kubectl patch {} -p "{\"imagePullSecrets\": [{\"name\": \"image-pull-secret\"}]}"' sh
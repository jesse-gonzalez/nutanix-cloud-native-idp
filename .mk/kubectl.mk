REQUIRED_TOOLS_LIST += kubectl krew jq

.PHONY: fix-image-pull-secrets-all
fix-image-pull-secrets-all: #### Add image pull secret to all available service accounts across all namespaces to get around image download rate limiting issues
	@kubectl get ns -o name | cut -d / -f2 | xargs -I {} sh -c "kubectl create secret docker-registry image-pull-secret --docker-username=${DOCKER_HUB_USER} --docker-password=${DOCKER_HUB_PASS} -n {} --dry-run=client -o yaml | kubectl apply -f - "
	@kubectl get serviceaccount --no-headers --all-namespaces | awk '{ print $$1 , $$2 }' | xargs -n2 sh -c 'kubectl patch serviceaccount $$2 -p "{\"imagePullSecrets\": [{\"name\": \"image-pull-secret\"}]}" -n $$1' sh

TARGET_NS ?= kasten-io
.PHONY: fix-image-pull-secrets-ns
fix-image-pull-secrets-ns: #### Add image pull secret to all available service accounts to target namespaces get around image download rate limiting issues. i.e., make fix-image-pull-secrets-ns 
	@kubectl create secret docker-registry image-pull-secret --docker-username=${DOCKER_HUB_USER} --docker-password=${DOCKER_HUB_PASS} -n ${TARGET_NS} --dry-run=client -o yaml | kubectl apply -f -
	@kubectl get serviceaccount -o name -n ${TARGET_NS} | xargs -I {} sh -c 'kubectl patch {} -p "{\"imagePullSecrets\": [{\"name\": \"image-pull-secret\"}]}"' sh


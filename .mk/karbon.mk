REQUIRED_TOOLS_LIST += kubectl krew jq

#download-karbon-creds download-all-karbon-cfgs fix-image-pull-secrets: print-vars

.PHONY: check-karbon-context
check-karbon-context: ### Validates that karbon kubectl context is valid and that cluster is reachable
	@export KUBECONFIG=$$KUBECONFIG:~/.kube/${KARBON_CLUSTER}.cfg; \
	[ ! -z "$$(kubectl config use-context ${KUBECTL_CONTEXT})" ] || make download-karbon-creds ENVIRONMENT=${ENVIRONMENT}

.PHONY: download-karbon-creds
download-karbon-creds: ### Leverage karbon krew/kubectl plugin to login, download kubeconfig and configure / add ssh keys
	@eval `ssh-agent -s` && KARBON_PASSWORD=${PC_PASSWORD} kubectl karbon login -k --server ${PC_IP_ADDRESS} --cluster ${KARBON_CLUSTER} --user ${PC_USER} --kubeconfig ~/.kube/${KARBON_CLUSTER}.cfg --ssh-file --ssh-agent --force
	@make merge-karbon-contexts

.PHONY: download-all-karbon-cfgs
download-all-karbon-cfgs: #### Download all kubeconfigs from all environments that have Karbon Cluster running
	@ls .local/*/nutanix.ncmstate | cut -d/ -f2 | xargs -I {} sh -c 'jq -r ".entities[].status | select((.description | contains(\"karbon-clusters\")) and (.state == \"running\")) | .name " .local/{}/nutanix.ncmstate' \
		| xargs -I {} grep -l {} .local/*/nutanix.ncmstate | cut -d/ -f2 | xargs -I {} make download-karbon-creds ENVIRONMENT={} && echo "reload shell. i.e., source ~/.zshrc and run kubectx to switch clusters"

.PHONY: merge-karbon-contexts
merge-karbon-contexts: #### Merge all K8s cluster kubeconfigs within path to config file.  Needed to support multiple clusters in future
	@export KUBECONFIG=$$KUBECONFIG:~/.kube/${KARBON_CLUSTER}.cfg; \
		kubectl config view --flatten >| ~/.kube/config && chmod 600 ~/.kube/config;
	@kubectl config use-context ${KUBECTL_CONTEXT};
	@kubectl cluster-info

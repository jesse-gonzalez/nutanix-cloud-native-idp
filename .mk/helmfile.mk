REQUIRED_TOOLS_LIST += helmfile helm

HELMFILE_CHART ?= nutanix-csi-storage
HELMFILE_EXTRA_ARGS	?= --include-transitive-needs

#helmfile-install helmfile-destroy helmfile-diff: check-karbon-context

.PHONY: helmfile-install
helmfile-install: #### Deploys Specific Helm Chart and it's Dependencies via Helmfile.
	helmfile -l name=${HELMFILE_CHART} --environment ${ENVIRONMENT} sync --concurrency 1 ${HELMFILE_EXTRA_ARGS};

.PHONY: helmfile-destroy
helmfile-destroy: #### Destroys Specific Helm Chart and it's Dependencies via Helmfile.
	helmfile -l name=${HELMFILE_CHART} --kube-context ${KUBECTL_CONTEXT} --environment ${ENVIRONMENT} destroy --concurrency 1;

.PHONY: helmfile-diff
helmfile-diff: init-rancher-kubectl #### Display difference of Local Helmfile and Deployed Resources.
	helmfile -l name=${HELMFILE_CHART} --kube-context ${KUBECTL_CONTEXT} --environment ${ENVIRONMENT} diff --concurrency 1;
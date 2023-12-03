REQUIRED_TOOLS_LIST += oc openshift-install

.PHONY: download-ocp-creds
set-ocp-creds: #### logs into ocp api for target environment.
	make set-bastion-host
	@export OCP_ADMIN_PASS=$(shell ssh -i .local/${ENVIRONMENT}/nutanix_key nutanix@${BASTION_HOST_SVM_IP} -C "cat .local/${OCP_CLUSTER_NAME}/.build-cache/auth/kubeadmin-password" ); \
		oc login --insecure-skip-tls-verify=true -u kubeadmin -p $$OCP_ADMIN_PASS ${OCP_API_URL}; \
		kubectl config view --raw --minify > ${HOME}/.kube/${OCP_CLUSTER_NAME}.cfg;

download-ocp-creds: set-ocp-creds ### Login to Openshift Cluster and set content to cluster name
	@export CURRENT_CONTEXT=$(shell kubectl config current-context); \
		kubectl config --kubeconfig ${HOME}/.kube/${OCP_CLUSTER_NAME}.cfg rename-context $$CURRENT_CONTEXT ${OCP_CLUSTER_NAME}; \
		export KUBECONFIG=${HOME}/.kube/${OCP_CLUSTER_NAME}.cfg; \
		kubectl config use-context ${OCP_CLUSTER_NAME};

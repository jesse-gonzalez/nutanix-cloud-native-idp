REQUIRED_TOOLS_LIST += clusterctl docker helmfile

CAPX_KUBECONFIG_PATH ?= $(HOME)/.kube/${CAPI_CLUSTER_NAME}.cfg
CAPX_KUBE_CONTEXT ?= ${CAPI_CLUSTER_NAME}-admin@${CAPI_CLUSTER_NAME}

CNI_HELMFILE_CHART := calico
CSI_HELMFILE_CHART := nutanix-csi-storage

KUBERNETES_VERSION ?= v1.27.1
CAPI_IMAGE_BUILD_NAME ?= ubuntu-2204-kube-v1.27.1.qcow2

.PHONY: delete-capi-all
delete-capi-all: #### stop running capi cluster
	@clusterctl delete --infrastructure nutanix --include-crd --include-namespace || \
		echo "capi cluster is not running"

.PHONY: install-image-builder
install-image-builder: #### installs capi image-builder 
	[ -d repo_cache ] || mkdir -p repo_cache \
	[ -d repo_cache/image-builder/images/capi/ ] || git clone --dissociate https://github.com/kubernetes-sigs/image-builder.git;

.PHONY: build-capi-image
build-capi-image: #### build capi image
	[ -d repo_cache/image-builder/images/capi/ ] || make install-image-builder
	cd repo_cache/image-builder/images/capi/; \
	make deps-nutanix && make build-nutanix-ubuntu-2204

#make terraform-apply TF_PATH=ahv/capi-imagebuilder ENVIRONMENT=${ENVIRONMENT}

.PHONY: upload-capi-image
upload-capi-image: #### upload capi image to binary repository (i.e., artifactory)
	curl -uadmin:<pass> -T terraform/ahv/capi-imagebuilder/output/${CAPI_IMAGE_BUILD_NAME}/${CAPI_IMAGE_BUILD_NAME}.qcow2 "http://artifactory.automationlab.local/artifactory/isos/capi/${CAPI_IMAGE_BUILD_NAME}.qcow2" --verbose

.PHONY: create-capi-mgmt-cluster
create-capi-mgmt-cluster: #### initialize capi controller manager
	@kubectl get deployment capi-controller-manager -n capi-system || clusterctl init --infrastructure nutanix

.PHONY: create-capi-wkl-cluster
create-capi-wkl-cluster: #### create capi workload cluster
	@kubectl create ns $(CAPI_COMMON_CLUSTER_NS) --dry-run=client -o yaml | kubectl apply -f - ; \
		clusterctl generate cluster ${CAPI_CLUSTER_NAME} -i nutanix --target-namespace ${CAPI_COMMON_CLUSTER_NS} | kubectl apply -n $(CAPI_COMMON_CLUSTER_NS) -f - ;

.PHONY: bootstrap-capi-cluster
bootstrap-capi-cluster: build-capi-image create-capi-mgmt-cluster create-capi-wkl-cluster get-capi-creds config-capi-cni config-capi-csi

.PHONY: get-capi-creds
get-capi-creds: #### get capi cluster creds
	clusterctl get kubeconfig $(CAPI_CLUSTER_NAME) --namespace $(CAPI_COMMON_CLUSTER_NS) > $(CAPX_KUBECONFIG_PATH); \
	export KUBECONFIG=$$KUBECONFIG:$(CAPX_KUBECONFIG_PATH); \
		kubectl config view --flatten >| ~/.kube/config && chmod 600 ~/.kube/config; \
		kubectl config use-context ${CAPX_KUBE_CONTEXT}; \
		kubectl cluster-info

.PHONY: config-capi-cni
config-capi-cni: get-capi-creds #### configure cni driver
	make helmfile-install HELMFILE_CHART=${CNI_HELMFILE_CHART} ENVIRONMENT=${CAPI_CLUSTER_NAME} KUBECTL_CONTEXT=${CAPX_KUBE_CONTEXT};

.PHONY: config-capi-csi
config-capi-csi: get-capi-creds #### configure csi driver
	make helmfile-install HELMFILE_CHART=${CSI_HELMFILE_CHART} ENVIRONMENT=${CAPI_CLUSTER_NAME} KUBECTL_CONTEXT=${CAPX_KUBE_CONTEXT};


# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.27.2.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.26.5.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.25.10.qcow2

# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.27.2.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.26.5.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.25.10.qcow2

# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.27.2.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.26.5.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.25.10.qcow2

# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.28.1.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.28.1.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.28.1.qcow2

# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.27.5.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.27.5.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.27.5.qcow2

# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.26.8.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.26.8.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.26.8.qcow2

# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.25.13.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.25.13.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.25.13.qcow2


# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.28.2.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.27.6.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.26.9.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/ubuntu-2204-kube-v1.25.14.qcow2


# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.28.2.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.27.6.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.26.9.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/windows-2022-kube-v1.25.14.qcow2

# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.28.2.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.27.6.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.26.9.qcow2
# https://capx-img.s3.eu-west-3.amazonaws.com/rockylinux-9-kube-v1.25.14.qcow2












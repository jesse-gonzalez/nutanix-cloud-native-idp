REQUIRED_TOOLS_LIST += kind docker helmfile

## expects c1 or c2 in config folder name. i.e., config/kalm-kind-11-1-c1.  needed for multi-cluster testing
KIND_CLUSTER_ID=$(shell echo ${ENVIRONMENT} | cut -d- -f5)
KIND_MULTI_CLUSTER_ID=$(shell echo ${KIND_CLUSTER_ID} | tr -d c)

KIND_CLUSTER_NAME ?= ${ENVIRONMENT}
KUBECONFIG_PATH ?= $(HOME)/.kube/$(KIND_CLUSTER_NAME).cfg

## calico is default. cilium is alternative option
CNI_HELMFILE_CHART := calico
CSI_HELMFILE_CHART := nutanix-csi-storage

KIND_CONFIG_FILE ?= kind/kind-${KIND_CLUSTER_ID}-config.yaml
METALLB_CONFIG_FILE ?= kind/metallb-${KIND_CLUSTER_ID}-config.yaml
CALICO_CONFIG_FILE ?= kind/calico-${KIND_CLUSTER_ID}-config.yaml

.PHONY: kind-build-csi-image
kind-build-csi-image: #### build kind node image to include iscsi and nfs client
	[ -n "$$(docker image ls kindest/node:v1.22.5 -q)" ] || xargs -I {} docker rmi -f {}
	docker build -t kindest/node:v1.22.5 -f kind/Dockerfile .

.PHONY: kind-stop
kind-stop: #### stop running kind cluster
	@kind delete cluster --name $(KIND_CLUSTER_NAME) || \
		echo "kind cluster is not running"

.PHONY: kind-start
kind-start: #### start kind cluster
	@kind get clusters | grep $(KIND_CLUSTER_NAME) || \
		kind create cluster --name $(KIND_CLUSTER_NAME) --kubeconfig $(KUBECONFIG_PATH) --config ${KIND_CONFIG_FILE};
	@make kind-get-creds ENVIRONMENT=${KIND_CLUSTER_NAME}

.PHONY: kind-get-creds
kind-get-creds: #### get kind cluster creds
	[ -d ~/.kube ] || mkdir -p ~/.kube;
	[ -f /.dockerenv ] || kind get kubeconfig --name $(KIND_CLUSTER_NAME) > $(KUBECONFIG_PATH);
	[ ! -f /.dockerenv ] || kind get kubeconfig --internal --name $(KIND_CLUSTER_NAME) > $(KUBECONFIG_PATH);
	export KUBECONFIG=$$KUBECONFIG:$(KUBECONFIG_PATH); \
		kubectl config view --flatten >| ~/.kube/config && chmod 600 ~/.kube/config; \
		kubectl config use-context kind-${KIND_CLUSTER_NAME}; \
		kubectl cluster-info

.PHONY: kind-config-cni
kind-config-cni: kind-start #### configure cni driver
	@make helmfile-install HELMFILE_CHART=${CNI_HELMFILE_CHART} ENVIRONMENT=${KIND_CLUSTER_NAME}

.PHONY: kind-config-csi
kind-config-csi: kind-start #### configure csi driver
	@make helmfile-install HELMFILE_CHART=${CSI_HELMFILE_CHART} ENVIRONMENT=${KIND_CLUSTER_NAME}

.PHONY: kind-bootstrap
kind-bootstrap: kind-start kind-get-creds kind-config-cni kind-config-csi

.PHONY: kind-reset
kind-reset: kind-stop kind-build-csi-image kind-bootstrap #### reset entire cluster config

.PHONY: kind-config-metallb
kind-config-metallb: kind-start #### install metallb
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/namespace.yaml
	kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(shell openssl rand -base64 128)" --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/metallb.yaml
	kubectl apply -f ${METALLB_CONFIG_FILE}

.PHONY: kind-config-calico-mc
kind-config-calico-mc: kind-start #### configure cilium multicluster
	make kind-config-cni CNI_HELMFILE_CHART=calico ENVIRONMENT=${KIND_CLUSTER_NAME}
	make kind-config-metallb ENVIRONMENT=${KIND_CLUSTER_NAME}
	kubectl apply -f ${CALICO_CONFIG_FILE}

.PHONY: kind-config-cilium-mc
kind-config-cilium-mc: kind-start #### configure cilium multicluster
	make kind-config-cni CNI_HELMFILE_CHART=cilium ENVIRONMENT=${KIND_CLUSTER_NAME}
	make kind-config-metallb ENVIRONMENT=${KIND_CLUSTER_NAME}
	cilium status
	cilium clustermesh enable --context kind-${KIND_CLUSTER_NAME} --service-type LoadBalancer --create-ca;
	cilium clustermesh status --context kind-${KIND_CLUSTER_NAME} --wait

## cilium clustermesh connect --context kind-kalm-kind-11-1-c1 --destination-context kind-kalm-kind-11-1-c2
## cilium clustermesh status --context kind-kalm-kind-11-1-c1 --wait
## cilium clustermesh status --context kind-kalm-kind-11-1-c2 --wait
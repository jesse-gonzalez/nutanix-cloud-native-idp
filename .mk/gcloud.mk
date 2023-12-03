REQUIRED_TOOLS_LIST += docker

#GCLOUD_DOCKER_CLI := docker run --rm --volumes-from gcloud-config gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine gcloud

GCP_SVC_ACCT_KEY_PATH := .local/_common/gcp_service_key.json
GCP_PROJECT_ID := $(shell cat ${GCP_SVC_ACCT_KEY_PATH} 2>/dev/null | jq .project_id -r)
GCP_SVC_ACCT_SPN := $(shell cat ${GCP_SVC_ACCT_KEY_PATH} 2>/dev/null | jq .client_email -r)
GCP_DEFAULT_COMPUTE_REGION := us-east4
GCP_DEFAULT_COMPUTE_ZONE := us-east4-a

.PHONY: config-gcloud-creds
config-gcloud-creds: #### Configures gcloud creds for service account json path
	gcloud auth activate-service-account ${GCP_SVC_ACCT_SPN} --key-file=${GCP_SVC_ACCT_KEY_PATH} --project=${GCP_PROJECT_ID}
	gcloud config set project ${GCP_PROJECT_ID}
	gcloud config set compute/region ${GCP_DEFAULT_COMPUTE_REGION}
	gcloud config set compute/zone ${GCP_DEFAULT_COMPUTE_ZONE}
	gcloud config list

.PHONY: enable-gcloud-apis
enable-gcloud-apis: config-gcloud-creds #### Enable gcloud apis for anthos, kubeflow and gke deployments
	gcloud services enable \
		cloudresourcemanager.googleapis.com \
		anthos.googleapis.com \
		container.googleapis.com \
		gkeconnect.googleapis.com \
		gkehub.googleapis.com;
	gcloud services enable \
		iamcredentials.googleapis.com \
		meshca.googleapis.com \
		meshconfig.googleapis.com \
		meshtelemetry.googleapis.com \
		monitoring.googleapis.com \
		runtimeconfig.googleapis.com\
		serviceusage.googleapis.com \
		compute.googleapis.com \
		iam.googleapis.com \
		servicemanagement.googleapis.com \
		ml.googleapis.com \
		iap.googleapis.com \
		sqladmin.googleapis.com \
		krmapihosting.googleapis.com \
		servicecontrol.googleapis.com \
		endpoints.googleapis.com \
		cloudbuild.googleapis.com

.PHONY: config-gcloud-components
config-gloud-components: #### Configure gcloud components
	gcloud components install kubectl kustomize kpt anthoscli beta
	gcloud components update

.PHONY: register-anthos-nke
register-anthos-nke: #### Registers karbon nke cluster into anthos
	gcloud container hub memberships register ${KARBON_CLUSTER} \
		--context=${KUBECTL_CONTEXT} \
		--service-account-key-file=${GCP_SVC_ACCT_KEY_PATH} \
		--kubeconfig=~/.kube/${KARBON_CLUSTER}.cfg \
		--project=${GCP_PROJECT_ID};


## cat .local/_common/gcp_service_key.json | docker login -u _json_key_base64 --password-stdin \
https://us-east4-docker.pkg.dev/ntnx-sa-demos

# # Create ALLOW ALL Ingress Rule
# ```
# gcloud compute firewall-rules create allow-all \
# 		--direction=INGRESS \
# 		--priority=1000 \
# 		--network=default \
# 		--action=ALLOW \
# 		--rules=all \
# 		--source-ranges=0.0.0.0/0 \
# 		--target-tags=allow-all	
# ```

# # Create a Static IP to use it as a GCE External IP Address
# ```
# gcloud compute addresses create static-ip --region=us-central1
# ```

# # Fetch the Static IP 
# ```
# gcloud compute addresses describe static-ip --region=us-central1
# ```

# # Create GCE Instance
# ```
# gcloud compute instances create devsecops-cloud --zone=us-central1-a \
#     --image=ubuntu-1804-bionic-v20210514 \
#     --image-project=ubuntu-os-cloud \
#     --machine-type=e2-standard-4 \
#     --address=<add-static-ip-from-previous-step> \
#     --network-tier=PREMIUM \
#     --boot-disk-size=512GB \
#     --tags=allow-all 
# ```
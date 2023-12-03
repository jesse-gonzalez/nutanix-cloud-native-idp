REQUIRED_TOOLS_LIST += terraform

TF_PATH	?= ahv/upload-images

TF_NAME	:= $(shell echo ${TF_PATH} | tr "/" "-")

TF_WORKSPACE_DIR := $(CURDIR)/terraform.tfstate.d/${ENVIRONMENT}

TF_PLAN_PATH := ${TF_WORKSPACE_DIR}/${TF_NAME}-tfplan.out
TF_STATE_PATH := ${TF_WORKSPACE_DIR}/${TF_NAME}-terraform.tfstate

terraform-apply terraform-destroy: terraform-plan

.PHONY: terraform-init
terraform-init: #### Initialize terraform workspace and cache
	[ -d ${TF_WORKSPACE_DIR} ] || terraform workspace new ${ENVIRONMENT}
	terraform workspace select ${ENVIRONMENT}; \
	cd terraform/${TF_PATH}; \
	terraform init -upgrade;

# .PHONY: terraform-init
# terraform-init: #### Initialize terraform workspace with Nutanix Objects S3
# 	[ -d ${TF_WORKSPACE_DIR} ] || terraform workspace new ${ENVIRONMENT}
# 	@terraform workspace select ${ENVIRONMENT}; \
# 	cd terraform/${TF_PATH}; \
# 	terraform init -upgrade -reconfigure -backend-config="access_key=${OBJECTS_ACCESS_KEY}" -backend-config="secret_key=${OBJECTS_SECRET_KEY}"

.PHONY: terraform-plan
terraform-plan: terraform-init #### Initializes terraform plan and State Files. i.e., make terraform-plan TF_PATH=ahv/upload-images ENVIRONMENT=kalm-main-11-2
	cd terraform/${TF_PATH}; \
	terraform plan -out=${TF_PLAN_PATH} -state=${TF_STATE_PATH};

.PHONY: terraform-apply
terraform-apply: #### Applies terraform plan and updates target resources. i.e., make terraform-apply TF_PATH=ahv/upload-images ENVIRONMENT=kalm-main-11-2
	cd terraform/${TF_PATH}; \
	terraform apply -parallelism=1 -lock=false -auto-approve -state=${TF_STATE_PATH} ${TF_PLAN_PATH};

.PHONY: terraform-destroy
terraform-destroy: #### Applies terraform plan and destroys target resources. i.e., make terraform-destroy TF_PATH=ahv/upload-images ENVIRONMENT=kalm-main-11-2
	cd terraform/${TF_PATH}; \
	terraform apply -destroy -parallelism=1 -lock=false -auto-approve -state=${TF_STATE_PATH} ${TF_PLAN_PATH};

.DEFAULT_GOAL := help

ENVIRONMENT ?= kalm-main-20-1
REQUIRED_TOOLS_LIST ?=

## load common variables and anything environment specific that overrides
export ENV_GLOBAL_PATH 	 := $(CURDIR)/config/_common/.env
export ENV_OVERRIDE_PATH := $(CURDIR)/config/${ENVIRONMENT}/.env

## create default config dirs if it doesn't exist at all.
ifeq (,$(wildcard $(ENV_OVERRIDE_PATH)))
CONFIG_DIR_EXISTS := $(shell mkdir -p $(CURDIR)/config/${ENVIRONMENT} && cp -r $(CURDIR)/config/templates/default.env $(ENV_OVERRIDE_PATH) && cp -r $(CURDIR)/config/_common/*.yaml $(CURDIR)/config/${ENVIRONMENT}/)
endif

## create default .local dirs if it doesn't exist at all.
ifeq (,$(wildcard $(SECRETS_ENV_PATH)))
SECRETS_DIR_EXISTS := $(shell mkdir -p $(CURDIR)/.local/_common $(CURDIR)/.local/${ENVIRONMENT} && cp -r $(CURDIR)/.local/_common/[^sops_gpg_key]* $(CURDIR)/.local/${ENVIRONMENT}/)
endif

## include optional modules from .mk folder
MODULES := utils git docker kubectl kind karbon terraform packer calm az aws gcloud helmfile capi rancher oc ansible
include $(patsubst %,.mk/%.mk,$(MODULES))

## import GPG keys for all environments in .local folder
GPG_IMPORT = $(shell find .local -name sops_gpg_key | egrep -i "common|${ENVIRONMENT}" | xargs -I {} gpg --quiet --import {} 2>/dev/null)

## import common/global and environment specific override variables
include $(ENV_GLOBAL_PATH)
-include $(ENV_OVERRIDE_PATH)

export

##########
## SCENARIOS/WORKFLOWS

init-bastion-host-svm set-bastion-host update-ssh-agent init-runbook-infra init-kalm-cluster upgrade-kalm-cluster init-helm-charts bootstrap-kalm-all bootstrap-reset-all: check-dsl-init

.PHONY: init-bastion-host-svm
init-bastion-host-svm: ### Initialize Karbon Admin Bastion Workstation. .i.e., make init-bastion-host-svm ENVIRONMENT=kalm-main-16-1
	@make create-dsl-bps launch-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT};
	@make set-bastion-host ENVIRONMENT=${ENVIRONMENT};

.PHONY: set-bastion-host
set-bastion-host: #### Update Dynamic IP for Linux Bastion Endpoint. .i.e., make set-bastion-host ENVIRONMENT=kalm-main-16-1
	@export BASTION_HOST_SVM_IP=$(shell calm get apps -n bastion-host-svm -q -l 1 --filter=_state==running | xargs -I {} calm describe app {} -o json | jq '.status.resources.deployment_list[0].substrate_configuration.element_list[0].address' | tr -d '"'); \
		grep -i BASTION_HOST_SVM_IP $(ENV_OVERRIDE_PATH) && sed -i "s/BASTION_HOST_SVM_IP =.*/BASTION_HOST_SVM_IP = $$BASTION_HOST_SVM_IP/g" $(ENV_OVERRIDE_PATH) || echo -e "\nBASTION_HOST_SVM_IP = $$BASTION_HOST_SVM_IP" >> $(ENV_OVERRIDE_PATH)

.PHONY: update-ssh-agent
update-ssh-agent: #### Adds Bastion Host Keys to local ssh agent
	@eval `ssh-agent -s` && cp .local/${ENVIRONMENT}/nutanix_key ~/.ssh/nutanix_key && chmod 600 ~/.ssh/nutanix_key && ssh-add ~/.ssh/nutanix_key

.PHONY: init-runbook-infra
init-runbook-infra: ### Initialize Calm Shared Infra from Endpoint, Runbook and Supporting Blueprints perspective. .i.e., make init-runbook-infra ENVIRONMENT=kalm-main-16-1
	@make set-bastion-host ENVIRONMENT=${ENVIRONMENT}
	@make create-all-dsl-endpoints ENVIRONMENT=${ENVIRONMENT}
	@make create-all-dsl-runbooks ENVIRONMENT=${ENVIRONMENT}
	@make run-all-dsl-runbook-scenarios RUNBOOK=update_aws_route53_dns ENVIRONMENT=${ENVIRONMENT}
	@make run-all-dsl-runbook-scenarios RUNBOOK=update_prism_central_certs ENVIRONMENT=${ENVIRONMENT}
	@sleep 120
	@make run-all-dsl-runbook-scenarios RUNBOOK=update_calm_categories ENVIRONMENT=${ENVIRONMENT}
	@make run-all-dsl-runbook-scenarios RUNBOOK=update_app_type_categories ENVIRONMENT=${ENVIRONMENT}
	@make run-all-dsl-runbook-scenarios RUNBOOK=update_ad_dns ENVIRONMENT=${ENVIRONMENT}
	@make run-all-dsl-runbook-scenarios RUNBOOK=update_objects_bucket ENVIRONMENT=${ENVIRONMENT}
	@make run-all-dsl-runbook-scenarios RUNBOOK=enable_policy_engine ENVIRONMENT=${ENVIRONMENT}
	@make run-all-dsl-runbook-scenarios RUNBOOK=enable_showback ENVIRONMENT=${ENVIRONMENT}

.PHONY: init-helm-charts
init-helm-charts: ### Intialize Helm Chart Marketplace. i.e., make init-helm-charts ENVIRONMENT=kalm-main-16-1
	@make create-all-helm-charts ENVIRONMENT=${ENVIRONMENT}

.PHONY: init-kalm-cluster
init-kalm-cluster: ### Initialize Karbon Cluster. i.e., make init-kalm-cluster ENVIRONMENT=kalm-main-16-1
	@make set-bastion-host ENVIRONMENT=${ENVIRONMENT}
	@make run-dsl-runbook RUNBOOK=update_ad_dns SCENARIO=create_bastion_host_ws_dns_params ENVIRONMENT=${ENVIRONMENT}
	@make create-dsl-bps launch-dsl-bps DSL_BP=karbon_cluster_deployment ENVIRONMENT=${ENVIRONMENT}

.PHONY: init-ocp-cluster
init-ocp-cluster: ### Initialize Openshift Cluster. i.e., make init-openshift-cluster ENVIRONMENT=kalm-main-16-1
	@make set-bastion-host ENVIRONMENT=${ENVIRONMENT}
	@make run-dsl-runbook RUNBOOK=update_ad_dns SCENARIO=create_bastion_host_ws_dns_params ENVIRONMENT=${ENVIRONMENT}
	@make create-dsl-bps DSL_BP=openshift_cluster_ipi ENVIRONMENT=${ENVIRONMENT}
	@make launch-dsl-bps DSL_BP=openshift_cluster_ipi ENVIRONMENT=${ENVIRONMENT}

.PHONY: init-rancher-rke2-cluster
init-rancher-rke2-cluster: ### Initialize Rancher on RKE2 Cluster. i.e., make init-rancher-rke2-cluster ENVIRONMENT=kalm-main-16-1
	@make set-bastion-host ENVIRONMENT=${ENVIRONMENT}
	@make run-dsl-runbook RUNBOOK=update_ad_dns SCENARIO=create_bastion_host_ws_dns_params ENVIRONMENT=${ENVIRONMENT}
	@make create-dsl-bps DSL_BP=rke2_on_ahv ENVIRONMENT=${ENVIRONMENT}
	@make launch-dsl-bps DSL_BP=rke2_on_ahv ENVIRONMENT=${ENVIRONMENT}

.PHONY: upgrade-kalm-cluster
upgrade-kalm-cluster: ### Upgrades existing karbon cluster to ensure that nke management agents are deployed to all clusters.
	@make run-dsl-day2-actions DSL_BP=karbon_cluster_deployment TEST_PARAMS_FILENAME=test_default_params.py ACTION_NAME="Upgrade Kubernetes Version" ENVIRONMENT=${ENVIRONMENT};

.PHONY: bootstrap-kalm-all
bootstrap-kalm-all: ### Bootstrap Bastion Host, Shared Infra and Karbon Cluster. i.e., make bootstrap-kalm-all ENVIRONMENT=kalm-main-16-1
	@make init-dsl-config ENVIRONMENT=${ENVIRONMENT}
	@make update-ssh-agent ENVIRONMENT=${ENVIRONMENT}
	@make init-bastion-host-svm ENVIRONMENT=${ENVIRONMENT}
	@make init-runbook-infra ENVIRONMENT=${ENVIRONMENT}
	@make init-kalm-cluster ENVIRONMENT=${ENVIRONMENT}
	@make download-karbon-creds ENVIRONMENT=${ENVIRONMENT}
	@make publish-all-blueprints ENVIRONMENT=${ENVIRONMENT}
	@make upgrade-kalm-cluster ENVIRONMENT=${ENVIRONMENT}

.PHONY: bootstrap-ocp-hub-all
bootstrap-ocp-hub-all: ### Bootstrap Bastion Host, Shared Infra and Openshift ACM OCP HUB Cluster. i.e., make bootstrap-ocp-all ENVIRONMENT=kalm-main-16-1
	@make init-dsl-config ENVIRONMENT=${ENVIRONMENT}
	@make update-ssh-agent ENVIRONMENT=${ENVIRONMENT}
	@make init-bastion-host-svm ENVIRONMENT=${ENVIRONMENT}
	@make init-runbook-infra ENVIRONMENT=${ENVIRONMENT}
	@make init-ocp-cluster ENVIRONMENT=${ENVIRONMENT}
	@make download-ocp-creds ENVIRONMENT=${ENVIRONMENT}
	@make publish-all-blueprints ENVIRONMENT=${ENVIRONMENT}

.PHONY: bootstrap-rancher-rke2-all
bootstrap-rancher-rke2-all: ### Bootstrap Bastion Host, Shared Infra and Rancher Cluster. i.e., make bootstrap-rancher-rke2-all ENVIRONMENT=kalm-main-16-1
	@make init-dsl-config ENVIRONMENT=${ENVIRONMENT}
	@make update-ssh-agent ENVIRONMENT=${ENVIRONMENT}
	@make init-bastion-host-svm ENVIRONMENT=${ENVIRONMENT}
	@make init-runbook-infra ENVIRONMENT=${ENVIRONMENT}
	@make init-rancher-rke2-cluster ENVIRONMENT=${ENVIRONMENT}
	@make download-rancher-creds ENVIRONMENT=${ENVIRONMENT}
	@make publish-all-blueprints ENVIRONMENT=${ENVIRONMENT}
 
.PHONY: bootstrap-reset-all
bootstrap-reset-all: ### WARNING: This WILL delete ALL existing apps, blueprints, runbooks, endpoints found in calm environment. i.e., make bootstrap-reset-all ENVIRONMENT=kalm-main-16-1
	@calm get apps --limit 50 -q --filter=_state==provisioning | grep -v "No application found" | xargs -I {} -t sh -c "calm stop app {} --watch 2>/dev/null";
	@calm get apps --limit 50 -q --filter=_state==deleting | grep -v "No application found" | xargs -I {} -t sh -c "calm stop app {} --watch 2>/dev/null";
	@calm get apps --limit 50 -q --filter=_state==error | grep -v "No application found" | xargs -I {} -t sh -c "calm delete app {}";
	@calm get apps --limit 50 -q --filter=_state==running | egrep -v "ocp|karbon|bastion" | grep -v "No application found" | xargs -I {} -t sh -c "calm delete app --soft {}";
	@calm get apps -q -n ocp --filter=_state==running | grep -v "No application found" | xargs -I {} -t sh -c "calm delete app {}";
	@sleep 90
	@calm get apps -q -n karbon --filter=_state==running | grep -v "No application found" | xargs -I {} -t sh -c "calm delete app {}";
	@calm get apps -q -n bastion --filter=_state==running | grep -v "No application found" | xargs -I {} -t sh -c "calm delete app {}";
	@calm get bps --limit 50 -q | grep -v "No blueprint found" | xargs -I {} -t sh -c "calm delete bp {}";
	@calm get runbooks -q | grep -v "No runbook found" | xargs -I {} -t sh -c "calm delete runbook {}";
	@calm get endpoints -q | grep -v "No endpoint found" | xargs -I {} -t sh -c "calm delete endpoint {}";

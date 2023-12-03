REQUIRED_TOOLS_LIST += calm git

# default settings
DSL_BP ?= karbon_cluster_deployment

####
## Configure Calm DSL and Docker Container
####

.PHONY: check-dsl-init
check-dsl-init: #### Validate whether calm init dsl needs to be executed with target environment.
	[ -d ${CALM_DSL_LOCAL_DIR_LOCATION} ] || make init-dsl-config ENVIRONMENT=${ENVIRONMENT}
	@calm get apps -o json 2>/dev/null > .local/${ENVIRONMENT}/nutanix.ncmstate;

## export DSL_ACCOUNT_IP=$(shell calm describe account NTNX_LOCAL_AZ | grep 'IP' | cut -d: -f2 | tr -d " " 2>/dev/null); \
##		[ "$$DSL_ACCOUNT_IP" == "${PC_IP_ADDRESS}" ] || make init-dsl-config ENVIRONMENT=${ENVIRONMENT};

.PHONY: init-dsl-config
init-dsl-config: ### Initialize calm dsl configuration with environment specific configs.  Assumes that it will be running withing Container.
	[ -f /.dockerenv ] || make docker-run ENVIRONMENT=${ENVIRONMENT}
	[ -d ${CALM_DSL_LOCAL_DIR_LOCATION} ] || mkdir -p ${CALM_DSL_LOCAL_DIR_LOCATION} && cp -rf .local/* /root/.calm
	[ -f ${CALM_DSL_CONFIG_FILE_LOCATION} ] || touch ${CALM_DSL_CONFIG_FILE_LOCATION} ${CALM_DSL_DB_LOCATION}
	calm init dsl --project "${CALM_PROJECT}"

#	@mkdir -p ${CALM_DSL_LOCAL_DIR_LOCATION} && cp -rf .local/* /root/.calm; \
#	@touch ${CALM_DSL_CONFIG_FILE_LOCATION} ${CALM_DSL_DB_LOCATION}; \

## Common BP command based on DSL_BP path passed in. To Run, make create-dsl-bps <dsl_bp_folder_name>

create-dsl-bps launch-dsl-bps delete-dsl-bps delete-dsl-apps: check-dsl-init

.PHONY: create-dsl-bps
create-dsl-bps: #### Create bp with corresponding git feature branch and short sha code. i.e., make create-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/${DSL_BP} create-bp

.PHONY: launch-dsl-bps
launch-dsl-bps: #### Launch Blueprint that matches your git feature branch and short sha code. i.e., make launch-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/${DSL_BP} launch-bp

.PHONY: delete-dsl-bps
delete-dsl-bps: #### Delete Blueprint that matches your git feature branch and short sha code. i.e., make delete-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/${DSL_BP} delete-bp

.PHONY: delete-dsl-apps
delete-dsl-apps: #### Delete Application that matches your git feature branch and short sha code. i.e., make delete-dsl-apps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/${DSL_BP} delete-app

## INTEGRATION TESTING

## Run day 2 actions for various use cases.

.PHONY: run-dsl-day2-actions
run-dsl-day2-actions: check-dsl-init #### Run Day 2 Actions against running application. make run-dsl-day2-actions DSL_BP=karbon_cluster_deployment ACTION_NAME="Upgrade Kubernetes Version"
	@make -C dsl/blueprints/${DSL_BP} run-action TEST_PARAMS_FILENAME=${TEST_PARAMS_FILENAME} ACTION_NAME="${ACTION_NAME}"

## RELEASE MANAGEMENT

## Following should be run from master branch along with git tag v1.0.x-$(git rev-parse --short HEAD), git push origin --tags, validate with git tag -l

publish-new-dsl-bps publish-existing-dsl-bps unpublish-dsl-bps: check-dsl-init

.PHONY: publish-new-dsl-bps
publish-new-dsl-bps: #### First Time Publish of Standard DSL BP. i.e., make publish-new-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/${DSL_BP} publish-new-bp

.PHONY: publish-existing-dsl-bps
publish-existing-dsl-bps: #### Publish Standard DSL BP of already existing. i.e., make publish-existing-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/${DSL_BP} publish-existing-bp

.PHONY: unpublish-dsl-bps
unpublish-dsl-bps: #### UnPublish Standard DSL BP of already existing. i.e., make unpublish-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}
	@make -k -C dsl/blueprints/${DSL_BP} unpublish-bp

## Helm charts specific commands

create-helm-bps launch-helm-bps delete-helm-bps delete-helm-apps create-all-helm-charts launch-all-helm-charts delete-all-helm-apps delete-all-helm-bps: check-dsl-init

.PHONY: create-helm-bps
create-helm-bps: #### Create single helm chart bp (with current git branch / tag latest in name). i.e., make create-helm-bps CHART=argocd ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/helm_charts/${CHART} create-bp

.PHONY: launch-helm-bps
launch-helm-bps: #### Launch single helm chart app (with current git branch / tag latest in name). i.e., make launch-helm-bps CHART=argocd ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/helm_charts/${CHART} launch-bp

.PHONY: delete-helm-bps
delete-helm-bps: #### Delete single helm chart blueprint (with current git branch / tag latest in name). i.e., make delete-helm-bps CHART=argocd ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/helm_charts/${CHART} delete-bp

.PHONY: delete-helm-apps
delete-helm-apps: #### Delete single helm chart app (with current git branch / tag latest in name). i.e., make delete-helm-apps CHART=argocd ENVIRONMENT=${ENVIRONMENT}
	@make -C dsl/blueprints/helm_charts/${CHART} delete-app

.PHONY: create-all-helm-charts
create-all-helm-charts: #### Create all helm chart blueprints with default test parameters (with current git branch / tag latest in name). i.e., make create-all-helm-charts ENVIRONMENT=${ENVIRONMENT}
	ls dsl/blueprints/helm_charts | xargs -I {} make create-helm-bps ENVIRONMENT=${ENVIRONMENT} CHART={}

.PHONY: launch-all-helm-charts
launch-all-helm-charts: #### Launch all helm chart blueprints with default test parameters (minus already deployed charts). i.e., make launch-all-helm-charts ENVIRONMENT=${ENVIRONMENT}
	ls dsl/blueprints/helm_charts | grep -v -E "kyverno|metallb|ingress-nginx|cert-manager" | xargs -I {} make launch-helm-bps ENVIRONMENT=${ENVIRONMENT} CHART={}

.PHONY: delete-all-helm-apps
delete-all-helm-apps: #### Delete all helm chart apps (with current git branch / tag latest in name). i.e., make delete-helm-apps ENVIRONMENT=kalm-main-16-1
	# remove pre-reqs last
	ls dsl/blueprints/helm_charts | grep -v -E "kyverno|metallb|ingress-nginx|cert-manager" | xargs -I {} make delete-helm-apps ENVIRONMENT=${ENVIRONMENT} CHART={}
	@make delete-helm-apps CHART=ingress-nginx ENVIRONMENT=${ENVIRONMENT}
	@make delete-helm-apps CHART=cert-manager ENVIRONMENT=${ENVIRONMENT}
	@make delete-helm-apps CHART=metallb ENVIRONMENT=${ENVIRONMENT}

.PHONY: delete-all-helm-bps
delete-all-helm-bps: #### Delete all helm chart blueprints (with current git branch / tag latest in name)
	ls dsl/blueprints/helm_charts | xargs -I {} make delete-helm-bps CHART={} ENVIRONMENT=${ENVIRONMENT}

## Endpoint specific commands

create-dsl-endpoint create-all-dsl-endpoints: check-dsl-init

.PHONY: create-dsl-endpoint
create-dsl-endpoint: #### Create Endpoint Resource. i.e., make create-dsl-endpoint EP=bastion_host_svm ENVIRONMENT=kalm-main-16-1
	@calm create endpoint -f ./dsl/endpoints/${EP}/endpoint.py --name ${EP} -fc 

.PHONY: create-all-dsl-endpoints
create-all-dsl-endpoints: #### Create ALL Endpoint Resources. i.e., make create-all-dsl-endpoints ENVIRONMENT=kalm-main-16-1
	ls dsl/endpoints | xargs -I {} make create-dsl-endpoint EP={} ENVIRONMENT=${ENVIRONMENT}

## Runbook specific commands

create-dsl-runbook create-all-dsl-runbooks run-dsl-runbook run-all-dsl-runbook-scenarios: check-dsl-init

.PHONY: create-dsl-runbook
create-dsl-runbook: #### Create Runbook. i.e., make create-dsl-runbook RUNBOOK=update_ad_dns ENVIRONMENT=kalm-main-16-1
	@calm create runbook -f ./dsl/runbooks/${RUNBOOK}/runbook.py --name ${RUNBOOK} -fc 

.PHONY: create-all-dsl-runbooks
create-all-dsl-runbooks: #### Create ALL Endpoint Resources. i.e., make create-all-dsl-runbooks ENVIRONMENT=kalm-main-16-1
	ls dsl/runbooks | xargs -I {} make create-dsl-runbook RUNBOOK={} ENVIRONMENT=${ENVIRONMENT}

.PHONY: run-dsl-runbook
run-dsl-runbook: #### Run Runbook with Specific Scenario. i.e., make run-dsl-runbook RUNBOOK=update_ad_dns SCENARIO=create_bastion_host_ws_dns_params ENVIRONMENT=kalm-main-16-1
	@calm run runbook -i --input-file ./dsl/runbooks/${RUNBOOK}/init-scenarios/${SCENARIO}.py ${RUNBOOK}

.PHONY: run-all-dsl-runbook-scenarios
run-all-dsl-runbook-scenarios: #### Runs all dsl runbook scenarios for given runbook i.e., make run-all-dsl-runbook-scenarios RUNBOOK=update_objects_bucket ENVIRONMENT=kalm-main-16-1
	@ls dsl/runbooks/${RUNBOOK}/init-scenarios/*.py | cut -d/ -f5 | cut -d. -f1 | xargs -I {} make run-dsl-runbook RUNBOOK=${RUNBOOK} SCENARIO={}

## RELEASE MANAGEMENT

## Following should be run from master branch along with git tag v1.0.x-$(git rev-parse --short HEAD), git push origin --tags, validate with git tag -l

# If needing to publish from a previous commit/tag than current master HEAD, from master, run git reset --hard tagname to set local working copy to that point in time.
# Run git reset --hard origin/master to return your local working copy back to latest HEAD.

publish-new-helm-bps publish-existing-helm-bps unpublish-helm-bps publish-all-new-helm-bps publish-all-existing-helm-bps publish-all-blueprints unpublish-all-blueprints: check-dsl-init

.PHONY: publish-new-helm-bps
publish-new-helm-bps: #### First Time Publish of Single Helm Chart. i.e., make publish-new-helm-bps CHART=argocd
	# promote stable release to marketplace for new
	@make -C dsl/blueprints/helm_charts/${CHART} publish-new-bp

.PHONY: publish-existing-helm-bps
publish-existing-helm-bps: #### Publish Single Helm Chart of already existing Helm Chart. i.e., make publish-existing-helm-bps CHART=argocd
	# promote stable release to marketplace for existing
	@make -C dsl/blueprints/helm_charts/${CHART} publish-existing-bp

.PHONY: unpublish-helm-bps
unpublish-helm-bps: #### Unpublish Single Helm Chart Blueprint - latest git release. i.e., make unpublish-helm-bps CHART=argocd
	# unpublish stable release to marketplace for existing
	@make -k -C dsl/blueprints/helm_charts/${CHART} unpublish-bp

.PHONY: publish-all-new-helm-bps
publish-all-new-helm-bps: #### First Time Publish of ALL Helm Chart Blueprints into Marketplace
	@ls dsl/blueprints/helm_charts | xargs -I {} make publish-new-helm-bps ENVIRONMENT=${ENVIRONMENT} CHART={}

.PHONY: publish-all-existing-helm-bps
publish-all-existing-helm-bps: #### Publish New Version of all existing helm chart marketplace items with latest git release.
	@ls dsl/blueprints/helm_charts | xargs -I {} make publish-existing-helm-bps ENVIRONMENT=${ENVIRONMENT} CHART={}

.PHONY: publish-all-blueprints
publish-all-blueprints: #### Publish all stable helm charts and blueprints
	if [ "$$(calm get marketplace bps | grep -i LOCAL | grep -v ExpressLaunch | cut -d\| -f8 | uniq | sort -r | head -n1 | xargs)" == "${MP_GIT_TAG}" ]; then \
		echo "Marketplace Item with Target Version already Published. Unpublishing now"; \
		make unpublish-all-blueprints ENVIRONMENT=${ENVIRONMENT}; \
	fi; \
	if [ -n "$$(calm get marketplace bps | grep -i LOCAL | grep -v ExpressLaunch | cut -d\| -f8 | uniq | sort -r | head -n1 | xargs)" ]; then \
		echo "Marketplace Items already exist, publishing new version with existing blueprint"; \
		make create-dsl-bps publish-existing-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-existing-dsl-bps DSL_BP=karbon_cluster_deployment ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-existing-dsl-bps DSL_BP=openshift_cluster_ipi ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-existing-dsl-bps DSL_BP=rke2_on_ahv ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-existing-dsl-bps DSL_BP=terraform/aks_cluster ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-existing-dsl-bps DSL_BP=terraform/eks_cluster ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-existing-dsl-bps DSL_BP=terraform/rke_on_ahv ENVIRONMENT=${ENVIRONMENT}; \
		make create-all-helm-charts publish-all-existing-helm-bps ENVIRONMENT=${ENVIRONMENT}; \
	else \
		echo "Publishing new blueprint"; \
		make create-dsl-bps publish-new-dsl-bps DSL_BP=bastion_host_svm ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-new-dsl-bps DSL_BP=karbon_cluster_deployment ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-new-dsl-bps DSL_BP=openshift_cluster_ipi ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-new-dsl-bps DSL_BP=rke2_on_ahv ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-new-dsl-bps DSL_BP=terraform/aks_cluster ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-new-dsl-bps DSL_BP=terraform/eks_cluster ENVIRONMENT=${ENVIRONMENT}; \
		make create-dsl-bps publish-new-dsl-bps DSL_BP=terraform/rke_on_ahv ENVIRONMENT=${ENVIRONMENT}; \
		make create-all-helm-charts publish-all-new-helm-bps ENVIRONMENT=${ENVIRONMENT}; \
	fi;

.PHONY: unpublish-all-blueprints
unpublish-all-blueprints: #### Un-publish all existing marketplace items, app icons and marketplace blueprints that match current git tag version.
	calm get marketplace items -d | grep ${MP_GIT_TAG}| awk '{ print $$2}' | xargs -I {} -t sh -c "calm unpublish marketplace bp -v ${MP_GIT_TAG} -s LOCAL {} && calm delete marketplace bp {} -v ${MP_GIT_TAG}";

.PHONY: seed-calm-task-library
seed-calm-task-library: check-dsl-init #### Seed the calm task library from nutanix blueprints github repo. make seed-calm-task-library ENVIRONMENT=kalm-main-16-1
	@rm -rf /tmp/blueprints
	@git clone https://github.com/nutanix/blueprints.git /tmp/blueprints
	@cd /tmp/blueprints/calm-integrations/generate_task_library_items
	@bash generate_task_library_items.sh
CATEGORY_NAME						:= KubernetesDistro

# Test params file name assumes that target folder is tests
TEST_PARAMS_FILENAME    ?= test_default_params.py
TEST_SCENARIO_NAME      := $(shell echo ${TEST_PARAMS_FILENAME} | cut -d. -f1 | cut -c 6-30)

# Default Action Name to run for custom day 2 actions
ACTION_NAME             := "Scale Out"

# Git Repo URL for Blueprint Description details
GIT_REPO_URL						:= $(shell git remote get-url origin | rev | cut -c5- | rev)

# Blueprint Git Tag remove dot notation because dots are not allowed in Blueprint Naming
BP_GIT_TAG              := $(shell git rev-list --tags --max-count=1 | xargs -I {} git describe --tags {} | tr -d '.')

# Marketplace Git Tag leaves dot notation and remove 'v' character to stay in line with existing semantic versioning guidelines
MP_GIT_TAG 			        := $(shell git rev-list --tags --max-count=1 | xargs -I {} git describe --tags {} | tr -d 'v')

MARKETPLACE_ICON_NAME   := terraform-eks-cluster
MARKETPLACE_ICON_LOC    := mp_meta/logo.png
MARKETPLACE_ITEM_NAME   := terraform-eks-cluster
MARKETPLACE_PRJ_LIST    ?= default

# Set Blueprint Prefix and Suffix Name
BLUEPRINT_PREFIX_NAME   := terraform-eks-cluster
BLUEPRINT_SUFFIX_NAME   :=
# if branch is master, then push with latest tag.  All builds from master should be considered a release and should have tag
## GIT_BRANCH_NAME, GIT_COMMIT_ID and CALM_ENVIRONMENT are passed in by parent Makefile as environment vars.
ifeq ($(GIT_BRANCH_NAME),main)
	ifeq ($(strip $(BP_GIT_TAG)),)
		BLUEPRINT_SUFFIX_NAME = ${GIT_BRANCH_NAME}-${GIT_COMMIT_ID}
	endif
	ifneq ($(strip $(BP_GIT_TAG)),)
		BLUEPRINT_SUFFIX_NAME = $(BP_GIT_TAG)
	endif
else
	BLUEPRINT_SUFFIX_NAME := ${GIT_BRANCH_NAME}-${GIT_COMMIT_ID}
endif

DSL_FILENAME := "blueprint.py"
BLUEPRINT_NAME := $(shell echo "${BLUEPRINT_PREFIX_NAME}-${BLUEPRINT_SUFFIX_NAME}" | tr '_' '-' | tr '/' '-')
APP_NAME := $(shell echo ${BLUEPRINT_PREFIX_NAME}-${CALM_ENVIRONMENT}-${TEST_SCENARIO_NAME}-$$RANDOM | tr '[:upper:]' '[:lower:]')

export

print-env:
	@echo "---LOCAL GIT ONLY - Specific Variables---"
	@echo GIT_BRANCH_NAME=${GIT_BRANCH_NAME}
	@echo GIT_COMMIT_ID=${GIT_COMMIT_ID}
	@echo BP_GIT_TAG=${BP_GIT_TAG}
	@echo MP_GIT_TAG=${MP_GIT_TAG}
	@echo DSL_FILENAME=${DSL_FILENAME}
	@echo BLUEPRINT_NAME=${BLUEPRINT_NAME}
	@echo APP_NAME=${APP_NAME}
	@echo MARKETPLACE_ITEM_NAME=${MARKETPLACE_ITEM_NAME}
	@echo MARKETPLACE_PRJ_LIST=${MARKETPLACE_PRJ_LIST}
	@echo TEST_PARAMS_FILENAME=${TEST_PARAMS_FILENAME}
	@echo TEST_SCENARIO_NAME=${TEST_SCENARIO_NAME}

create-bp:
	calm compile bp -f ${DSL_FILENAME}
	calm create bp -f ${DSL_FILENAME} --name ${BLUEPRINT_NAME} --force --description "See ${BLUEPRINT_NAME} Commit History: [${GIT_BRANCH_NAME}](${GIT_REPO_URL}/commit/${GIT_COMMIT_ID}) $$(cat mp_meta/bp-description.md)"
	calm describe bp ${BLUEPRINT_NAME}

launch-bp:
	calm launch bp ${BLUEPRINT_NAME} --app_name ${APP_NAME} --launch_params tests/${TEST_PARAMS_FILENAME} --watch --poll-interval 30
	calm get apps --name ${APP_NAME}
	# calm describe app ${APP_NAME}

run-action:
	calm run action --app ${APP_NAME} --runtime_params tests/${TEST_PARAMS_FILENAME} --watch ${ACTION_NAME}
	calm get apps --name ${APP_NAME}
	# calm describe app ${APP_NAME}

delete-bp:
	calm delete bp ${BLUEPRINT_NAME}

delete-app:
	calm delete app ${APP_NAME}

publish-new-bp:
	calm create app_icon -n ${MARKETPLACE_ICON_NAME} -f ${MARKETPLACE_ICON_LOC}
	calm publish bp -v ${MP_GIT_TAG} --with_secrets -n ${MARKETPLACE_ITEM_NAME} -i ${MARKETPLACE_ICON_NAME} -d "$$(cat mp_meta/mp-description.md)" --all_projects --publish_to_marketplace --category ${CATEGORY_NAME} ${BLUEPRINT_NAME}
	calm get marketplace bps -n ${MARKETPLACE_ITEM_NAME} -a PUBLISHED

publish-existing-bp:
	if [ -z "$$(calm get app_icons -n ${MARKETPLACE_ICON_NAME} -q)" ]; then \
		calm create app_icon -n ${MARKETPLACE_ICON_NAME} -f ${MARKETPLACE_ICON_LOC}; \
	fi;
	# Publish a new version of an existing blueprint to marketplace manager. This should only be executed from master stable branch.
	calm publish bp -v ${MP_GIT_TAG} --existing_markeplace_bp --with_secrets -n ${MARKETPLACE_ITEM_NAME} -i ${MARKETPLACE_ICON_NAME} -d "$$(cat mp_meta/mp-description.md)" --all_projects --publish_to_marketplace --category ${CATEGORY_NAME} ${BLUEPRINT_NAME}
	# service account doesn't have permission to auto-approve --publish_to_marketplace
	calm get marketplace bps -n ${MARKETPLACE_ITEM_NAME} -a PUBLISHED

unpublish-bp:
	# Unpublish blueprints from marketplace store
	calm unpublish marketplace bp -v ${MP_GIT_TAG} -s LOCAL ${MARKETPLACE_ITEM_NAME}

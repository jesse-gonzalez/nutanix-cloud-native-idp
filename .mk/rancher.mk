REQUIRED_TOOLS_LIST += rancher

RANCHER_API_ENDPOINT ?= https://rancher.automationlab.local/v3

RANCHER_UPSTREAM_CLUSTER ?= kalm-main-sa-lab
RANCHER_DOWNSTREAM_CLUSTER ?= kalm-main-sa-lab

## if rancher runs on default cluster you can query for name based on clustger
RANCHER_DEFAULT_PROJECT ?= local:p-g9xwz

.PHONY: config-rancher-creds
config-rancher-creds: #### Configures rancher cli creds
	rancher login --name "${RANCHER_UPSTREAM_CLUSTER}" --context "${RANCHER_DEFAULT_PROJECT}" --token "${RANCHER_ACCESS_KEY}:${RANCHER_ACCESS_SECRET}" --skip-verify ${RANCHER_API_ENDPOINT}

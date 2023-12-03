REQUIRED_TOOLS_LIST += az

.PHONY: config-az-creds
config-az-creds: #### Configures azure creds for cli
	@az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}
	@az account set --subscription ${AZURE_SUBSCRIPTION_ID}
	az account list -o table



REQUIRED_TOOLS_LIST += aws

.PHONY: config-aws-creds
config-aws-creds: #### Configures local aws credentials ~/.aws/config
	@aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
	@aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
	@aws configure set default.region ${AWS_DEFAULT_REGION}
	@aws configure list

.PHONY: check-aws-creds
check-aws-creds: #### Checks if local creds exists, otherwise runs config-aws-creds
	[ -f ~/.aws/credentials ] || make config-aws-creds ENVIRONMENT=${ENVIRONMENT}

.PHONY: clean-aws-creds
clean-aws-creds: #### Cleans out aws creds locally
	[ ! -f ~/.aws/credentials ] || rm -f ~/.aws/credentials
	[ ! -f ~/.aws/config ] || rm -f ~/.aws/config
	

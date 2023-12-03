REQUIRED_TOOLS_LIST += grep egrep sort awk cut printf tar yq

##############
## Helpers

.PHONY: help
help: ### Show default help options
	@egrep -h '\s###\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?### "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: help-all
help-all: ### Show all advanced help options
	@egrep -h '\s####\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?### "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: print-vars
print-vars: ### Print environment variables. i.e., make print-vars
	@for envvar in $$(cat $(ENV_GLOBAL_PATH) $(ENV_OVERRIDE_PATH) | cut -d= -f1 | sort -usf | xargs -n 1); do `echo env` | egrep -vi "USER|PASS|KEY|SECRET|CRED|TOKEN" | grep "$$envvar=" 2>/dev/null; done; 2>/dev/null

.PHONY: print-secrets
print-secrets: #### Print variables including secrets. i.e., make print-secrets
	@for envvar in $$(cat $(ENV_GLOBAL_PATH) $(ENV_OVERRIDE_PATH) | cut -d= -f1 | sort -usf | xargs -n 1); do `echo env` | egrep "USER|PASS|KEY|SECRET|CRED|TOKEN" | grep "$$envvar=" 2>/dev/null; done; 2>/dev/null

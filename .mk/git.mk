REQUIRED_TOOLS_LIST += git gh

promote-release run-gh-workflow-dispatch: github-login

.PHONY: github-login
github-login: #### Login to GitHub Repo to support local commits and tag promotion
	@echo -e "$(GITHUB_PASS)" | gh auth login --with-token
	@gh auth setup-git;
	@git config user.name "$(GITHUB_USER)";
	@git config user.email "$(GITHUB_EMAIL)";

.PHONY: promote-release
promote-release: #### Promote next version of git tag
	@git fetch --tags
	@echo "VERSION:$(GIT_VERSION) IS_SNAPSHOT:$(GIT_IS_SNAPSHOT) NEW_VERSION:$(GIT_NEW_VERSION)"
ifeq (false,$(GIT_IS_SNAPSHOT))
	@echo "Unable to promote a non-snapshot"
	@exit 1
endif
ifneq ($(shell git status -s),)
	@echo "Unable to promote a dirty workspace. Please commit and push your updates"
	@exit 1
endif
	@git tag -a -m "releasing v$(GIT_NEW_VERSION)" v$(GIT_NEW_VERSION)
	@git push origin v$(GIT_NEW_VERSION)

.PHONY: run-gh-workflow-dispatch
run-gh-workflow-dispatch: #### Run github actions dispatch workflow with common params. Github Repo admins only
	gh workflow run github-actions.yml --ref ${GIT_BRANCH_NAME} -f deploy_environment=${ENVIRONMENT} -f github_environment=kalm-main-common -f github_runner=actions-runner-set

.PHONY: run-ggshield-scan
run-ggshield-scan: #### Run git guardian cli scan against repo
	@echo "$(GITGUARDIAN_API_KEY)" | ggshield auth login --method token
	ggshield secret scan pre-commit
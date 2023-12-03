REQUIRED_TOOLS_LIST += docker jq git

DEFAULT_SHELL ?= /bin/bash
IMAGE_REGISTRY_ORG ?= ghcr.io/jesse-gonzalez

TARGET_RELEASE ?= $(GIT_LATEST_TAG)

.PHONY: docker-clean
docker-clean: #### Remove Calm DSL Util Image locally with necessary tools to develop and manage Cloud-Native Apps (e.g., kubectl, argocd, git, helm, helmfile, etc.)
	docker image ls --filter "reference=${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils" --format "{{.Repository}}:{{.Tag}}" | xargs -I {} docker rmi -f {}

.PHONY: docker-build
docker-build: docker-clean #### Build Calm DSL Util Image locally with necessary tools to develop and manage Cloud-Native Apps (e.g., kubectl, argocd, git, helm, helmfile, etc.)
	cd .devcontainer && docker build -t ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils:latest .
	docker tag ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils:$(TARGET_RELEASE)

.PHONY: docker-run
docker-run: ### Launch into Calm DSL development container. If image isn't available, build will auto-run
	[ -n "$$(docker image ls ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils:$(TARGET_RELEASE) -q)" ] || make docker-build
	docker run --rm -it \
		--network ${DOCKER_NETWORK} \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v `pwd`:/dsl-workspace \
		-w '/dsl-workspace' \
		-e ENVIRONMENT='${ENVIRONMENT}' \
		-e GITGUARDIAN_API_KEY='${GITGUARDIAN_API_KEY}' \
		${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils /bin/sh -c "make help && ${DEFAULT_SHELL}"

.PHONY: docker-login
docker-login: #### Login to Github Private Registry
	@echo "$(GITHUB_PASS)" | docker login ghcr.io --username $(GITHUB_USER) --password-stdin

.PHONY: docker-push
docker-push: docker-login ## Tag and Push latest image and short sha version to desired image repo.
	[ -n "$$(docker image ls ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils -q)" ] || make docker-build
	@docker push ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils:latest
	@docker tag ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils:$(GIT_COMMIT_ID)
	@docker push ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils:$(GIT_COMMIT_ID)

.PHONY: docker-release
docker-release: docker-login ## Tag and Push latest release to desired image repo.
	@docker tag ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils:$(GIT_LATEST_TAG)
	@docker push ${IMAGE_REGISTRY_ORG}/nutanix-cloud-native-utils:$(GIT_LATEST_TAG)

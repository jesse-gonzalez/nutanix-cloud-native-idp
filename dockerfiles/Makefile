
TARGET_REMOTE_REPO=ntnxdemo
TARGET_DOCKERFILE_PATH=jenkins
TARGET_IMAGE_NAME=jenkins
TARGET_VERSION=v0.1.4

build:
	docker build --no-cache -t ${TARGET_IMAGE_NAME} ${TARGET_DOCKERFILE_PATH}/.

tag:
	docker tag ${TARGET_IMAGE_NAME}:latest ${TARGET_REMOTE_REPO}/${TARGET_IMAGE_NAME}:${TARGET_VERSION}

push:
	docker push ${TARGET_REMOTE_REPO}/${TARGET_IMAGE_NAME}:${TARGET_VERSION}

clean:
	docker image ls --filter "reference=${TARGET_REMOTE_REPO}/${TARGET_IMAGE_NAME}" --format "{{.Repository}}:{{.Tag}}" | xargs -I {} docker rmi -f {}
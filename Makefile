## -----------------------------------------------------------------------------
## Make targets for building, publishing, and deploying this application.
## -----------------------------------------------------------------------------

# Dynamic variables - passed at runtime
GH_ORG?=tarpanpathak
DKR_REGISTRY?=ghcr.io
DKR_REGISTRY_TOKEN?=${GH_TOKEN}
DKR_REGISTRY_USER?=${GH_USER}
DKR_REPOSITORY?=${GH_ORG}/${APP}
DKR_IMG_SEMREL?=
DKR_IMG_TAG?=main
DKR_IMG?=${DKR_REGISTRY}/${DKR_REPOSITORY}:${DKR_IMG_TAG}

# Static variables
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
COMMIT=$(shell git rev-parse --short HEAD)
CWD=$(shell pwd)
APP=$(shell basename "${CWD}")
NODE_VERSION=v19.7.0
NPM_VERSION=9.5.0

# Avoid name collisions between targets and files.
.PHONY: help build run test release-dry release \
	build-docker run-docker login-docker push-docker logout-docker images-docker debug-docker clean-docker \
	clean-release clean-all

# A target to format and present all supported targets with their descriptions.
help : Makefile
		@sed -n 's/^##//p' $<

## build 		: Compile the application.
build:
	npm install

## run 		: Run the application.
run:
	node server.js

## test		: Test the application.
test:
	curl -i http://localhost:8080/

## release-dry 	: Generate a new the version without creating a new release.
release-dry: clean-release
	semantic-release \
		--token ${DKR_REGISTRY_TOKEN} \
		--allow-no-changes --dry --no-ci \
		--provider-opt "slug=tarpanpathak/${APP}"

## release 	: Generate a new SemVer based module tag using Semantic Release.
release:
	semantic-release \
		--token ${DKR_REGISTRY_TOKEN} \
		--allow-no-changes \
		--version-file \
		--provider-opt "slug=tarpanpathak/${APP}"	

## build-docker 	: Compile the application in Docker.
build-docker:
	docker build -t $(DKR_IMG) .

## run-docker 	: Run the application in Docker.
run-docker:
	docker run -p 8080:8080 --name ${APP} -d $(DKR_IMG)

## save-docker	: Save the Docker image for later use.
save-docker:
	docker save $(DKR_IMG) > ${APP}.tar

## load-docker	: Load the previously saved Docker image.
load-docker:
	docker load -i ${APP}.tar

## tag-docker 	: Tag the Docker image.
tag-docker:
	docker image tag $(DKR_IMG) $(DKR_IMG_SEMREL)

## login-docker	: Login to the Docker registry.
login-docker:
	@echo ${DKR_REGISTRY_TOKEN} | docker login \
		${DKR_REGISTRY} -u ${DKR_REGISTRY_USER} --password-stdin

## push-docker 	: Publish the Docker image to the Docker registry.
push-docker:
	docker push $(DKR_IMG_SEMREL)

## logout-docker	: Logout of the Docker registry.
logout-docker:
	@docker logout $(DKR_REGISTRY)

## images-docker	: List all the Docker images.
images-docker: 
	@docker images $(DKR_IMG)

## debug-docker 	: Launch an interactive Docker container for debugging.
debug-docker:
	@docker run -it --rm --entrypoint=/bin/sh $(DKR_IMG)

## clean-docker 	: Cleanup the application Docker image/s.
clean-docker:
	docker rm -f ${APP}
	docker rmi -f $(DKR_IMG)
	rm -rf ${APP}.tar

## clean-release 	: Cleanup the release artifacts.
clean-release:
	rm -rf .semrel/

## clean-all 	: Cleanup all temporary artifacts.
clean-all:
	clean-docker
	clean-release

# Author: Zachary Loeber
#
# Show more help
#  $ make

.SHELL:=/usr/bin/bash

VERSION?=$(shell echo $${BUILD_ID:-"0.0.1"})
CURRENT_FOLDER=$(shell basename "$$(pwd)")
ROOT_DIR:=$(abspath $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

PROJECT_PATH?=${ROOT_DIR}

## Sane default values (should be in your default .env)
DOCKERREGISTRY ?= curl
DOCKERFILE ?= Dockerfile_curl
DOCKER_REGISTRY_DOMAIN ?= docker.com
APP_IMAGE ?= curl

# Set to --no-cache to run docker build operations from scratch
DOCKER_NC?=

## Docker commands
DOCKER_CMD=docker
DOCKER_BUILD=$(DOCKER_CMD) build
DOCKER_TAG=$(DOCKER_CMD) tag
DOCKER_PUSH=$(DOCKER_CMD) push
DOCKER_RUN=$(DOCKER_CMD) run
DOCKER_RMI=$(DOCKER_CMD) rmi -f
DOCKER_EXEC=$(DOCKER_CMD) exec

## Docker (derived)
DOCKER_APP_IMAGE?=$(DOCKER_REGISTRY_DOMAIN)/$(APP_IMAGE)

################
.DEFAULT_GOAL:=help

.PHONY: clean deps install lint pep8 pyflakes pylint test baseimage help azdeploy

repo/login: ## Login to acr repo
	@az acr login --name ${DOCKERREGISTRY}

build: ## Build app images
	$(DOCKER_BUILD) . -f ${DOCKERFILE} -t ${DOCKER_APP_IMAGE} ${DOCKER_NC}

tag: ## Tag app image
	$(DOCKER_TAG) $(DOCKER_APP_IMAGE) $(DOCKER_APP_IMAGE):$(VERSION)

push: # Push an image
	$(DOCKER_PUSH) $(DOCKER_APP_IMAGE)

image: repo/login build tag push ## Build, tag, and deploy app images to ACR

run/shell: ## Run current docker image interactively (as root)
	$(DOCKER_RUN) -i -t --rm -u root --name="$(APP_IMAGE)" $(DOCKER_APP_IMAGE):$(VERSION) bash

run: ## Run current docker image interactively (as root)
	$(DOCKER_RUN) -i -t --rm -u root --name="$(APP_IMAGE)" $(DOCKER_APP_IMAGE):$(VERSION)

.cloud-context: ## Sets Azure subscription
	az account set --subscription "${AZ_SUBSCRIPTION}"

login: ## Login to Azure
	az login

## Reporting
.PHONY: help show/env show/brief
help: show/brief ## This help.
	@echo ''
	@awk 'BEGIN {FS=":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''

show/brief: ## Brief env
	@echo "************************"
	@echo 'VERSION: $(VERSION)'
	@echo 'DOCKERREGISTRY: $(DOCKERREGISTRY)'
	@echo 'DOCKERFILE: $(DOCKERFILE)'
	@echo 'DOCKERREGISTRY: $(DOCKERREGISTRY)'
	@echo 'DOCKER_REGISTRY_DOMAIN: $(DOCKER_REGISTRY_DOMAIN)'
	@echo 'APP_IMAGE: $(APP_IMAGE)'
	@echo "************************"

show/env: show/brief ## Environment and build information

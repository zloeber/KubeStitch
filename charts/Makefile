## Small helm chart build/deploy wrapper
## Author: Zachary Loeber
SHELL:=/bin/bash

CHART?=archetype
ORG?=adodevopsorg
REPO_NAME?=mycontainerrepo
REPO?=http://${REPO_NAME}.azurecr.io
VERSION?=0.0.1
CURRENT_FOLDER=$(shell basename "$$(pwd)")
ABS_PATH:=$(abspath $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))
ROOT_PATH:=$(shell dirname ${ABS_PATH})
PROJECT_PATH?=./${CHART}
LOCAL_PATH?=${PROJECT_PATH}/.local
BIN_PATH?=${LOCAL_PATH}/bin
SCRIPT_PATH?=${PROJECT_PATH}

.DEFAULT_GOAL:=help
.PHONY: deps clean helm/add helm/remove helm/package helm/push deploy devops/repo/create az/helm/add az/deploy prompt/yesno

$(BIN_PATH): ## Stage build directory if it does not exist
	@mkdir -p $(BIN_PATH)

clean: ## Clean up built helm charts
	rm -rf ${PROJECT_PATH}/charts/*.tgz
	rm -rf ${PROJECT_PATH}/*.lock

deps: clean dep/helm helm/init ## Update helm dependencies
	helm dependency update

az/init: ## Initialize Azure ACR
	az acr helm repo add -n mycontainerrepo --subscription "Your Subscription"

helm/add: ## Adds azure acr helm repo to local helm repo list
	helm repo remove chartmuseum 2>/dev/null || true
	helm repo add chartmuseum http://chartmuseum.${TEAM}.${TARGET}.micro.svc

helm/lint: ## Adds azure acr helm repo to local helm repo list
	helm lint ${PROJECT_PATH}

helm/remove: ## Remove azure acr helm repo to local helm repo list
	helm repo remove chartmuseum 2> /dev/null

helm/package: ## Builds and packages helm chart to ./charts
	helm package -u ${PROJECT_PATH}/ -d ./

helm/push: ## Push the packaged chart
	helm push ./charts/${CHART}-${VERSION}.tgz --force chartmuseum

help: ## Help
	@grep --no-filename -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

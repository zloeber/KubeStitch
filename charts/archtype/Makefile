## Small helm chart build/deploy wrapper
## Author: Zachary Loeber
SHELL:=/bin/bash

ORG?=adodevopsorg
ENGINE?=NextGen
TARGET?=a1d
TEAM?=inv
REPO_NAME?=mycontainerrepo
REPO?=http://${REPO_NAME}.azurecr.io
RELEASE?=stable
VERSION?=0.0.1

## Default to the chart name being this current folder
CHART?=$(shell basename "$$(pwd)")

CURRENT_FOLDER=$(shell basename "$$(pwd)")
ABS_PATH:=$(abspath $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))
ROOT_PATH:=$(shell dirname ${ABS_PATH})
PROJECT_PATH?=${ABS_PATH}
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

dep/helm: $(BIN_PATH) ## Installs helm binary
ifeq (,$(wildcard $(BIN_PATH)/helm))
	${SCRIPT_PATH}/helm-latest-release.sh
endif
	@echo "Installed Location: $(BIN_PATH)/helm"

az/deps: clean dep/helm az/config helm/init ## Azure dependencies
	$(BIN_PATH)/helm dependency update

deps: clean dep/helm helm/init ## Update helm dependencies
	$(BIN_PATH)/helm dependency update

helm/add: ## Adds azure acr helm repo to local helm repo list
	$(BIN_PATH)/helm repo remove chartmuseum 2>/dev/null || true
	$(BIN_PATH)/helm repo add chartmuseum http://chartmuseum.${TEAM}.${TARGET}.micro.svc

helm/init: ## Initializes helm properly
	$(BIN_PATH)/helm init -c

helm/lint: ## Adds azure acr helm repo to local helm repo list
	$(BIN_PATH)/helm lint ${PROJECT_PATH}

# az/helm/add: ## Adds azure acr helm repo to local helm repo list
# 	az acr helm repo add ${REPO} "${ORG}-${RELEASE}"

helm/remove: ## Remove azure acr helm repo to local helm repo list
	$(BIN_PATH)/helm repo remove chartmuseum 2> /dev/null

helm/package: ## Builds and packages helm chart to ./charts
	$(BIN_PATH)/helm package -u ${PROJECT_PATH}/ -d ${PROJECT_PATH}/charts

helm/push: ## Push the packaged chart
	$(BIN_PATH)/helm push ./charts/${CHART}-${VERSION}.tgz --force chartmuseum

az/config: ## Some azure defaults for this session
	az configure --defaults acr=${REPO_NAME}

az/helm/push: ## Push the packaged chart
	az acr helm push -n mycontainerrepo ${PROJECT_PATH}/charts/${CHART}-${VERSION}.tgz --force

az/helm/list: ## Show acr helm charts
	az acr helm list

deploy: deps helm/lint helm/init helm/add helm/package helm/push ## build, package, and push helm repo

az/deploy: deps az/config helm/init helm/lint helm/package az/helm/push ## Build and push helm repo to azure acr

prompt/yesno: ## Are you sure
	@( read -p "Are you sure?!? [y/N]: " sure && case "$$sure" in [yY]) true;; *) false;; esac )

## Some extra, nice to have, bootstrap tasks
.devops/repo/create: prompt/yesno ## Create devops repo for this project
	@echo "No repo for your chart yet? Great, start here but.."
	@echo "Just blow away the local .git folder first and ensure PROJECT is correct"
	@echo ""
	az repos create --name ${PROJECT} 2> /dev/null
	git remote add origin https://dev.azure.com/${ORG}/NextGen/_git/${CHART}
	git push -u origin --all

help: ## Help
	@grep --no-filename -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

show/env: ## Show env vars
	@echo "REPO=${REPO}"
	@echo "RELEASE=${RELEASE}"
	@echo "CHART=${CHART}"
	@echo "CURRENT_FOLDER=${CURRENT_FOLDER}"
	@echo "ABS_PATH=${ABS_PATH}"
	@echo "ROOT_PATH=${ROOT_PATH}"
	@echo "PROJECT_PATH=${PROJECT_PATH}"
	@echo "LOCAL_PATH=${LOCAL_PATH}"
	@echo "BIN_PATH=${BIN_PATH}"
	@echo "SCRIPT_PATH=${SCRIPT_PATH}"

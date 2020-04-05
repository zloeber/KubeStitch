## Small helm chart -> azure acr deployment wrapper
## Author: Zachary Loeber

TARGET?=a1d
PROJECT?=nextgen

## Local repo deployment
REPO?=${PROJECT}${TARGET}

## Default to the chart name being this current folder
CHART?=$(shell basename "$$(pwd)")

.DEFAULT_GOAL := deploy

.PHONY: deps login config helm/add helm/push deploy
deps: ## Update helm dependencies
	helm dependency update
login: ## Login to azure (if required)
	az login
config: ## Configure default ACR repo
	az configure --defaults acr=${REPO}
helm/add: ## Adds azure acr helm repo to local helm repo list
	az acr helm repo add -n ${REPO} 2> /dev/null
helm/remove: ## Remove azure acr helm repo to local helm repo list
	az acr helm repo add -n ${REPO} 2> /dev/null
helm/package: ## Builds and packages helm chart to ./charts
	helm package -u ./ -d ./charts
helm/push: ## Push the packaged chart to acr
	az acr helm push -n ${REPO} ./charts/${CHART}*.tgz --force
deploy: config helm/add helm/package helm/push ## build, package, and push helm repo to acr

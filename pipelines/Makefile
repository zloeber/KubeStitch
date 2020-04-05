SHELL:=/bin/bash
.DEFAULT_GOAL:=help

ORG=adodevopsorg
ENGINE=NextGen
GITREPO=CICD
REPO=ssh://git@ssh.dev.azure.com/v3/${ORG}/${ENGINE}/${GITREPO}
CURRENT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)

help: ## Help
	@grep -E '^[a-zA-Z_-/]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

add/pipelines: ## Add azure pipelines
	az pipelines create --skip-run --detect false --branch ${CURRENT_BRANCH} \
		--yaml-path /pipelines/azure-pipeline.archtype.yml \
		--name 'Helm Chart (archtype)' --repository ${GITREPO} --repository-type tfsgit || true
	az pipelines create --skip-run --detect false --branch ${CURRENT_BRANCH} \
		--yaml-path /pipelines/azure-pipeline.spark-history-server.yml \
		--name 'Helm Chart (spark-history-server)' --repository ${GITREPO} --repository-type tfsgit || true

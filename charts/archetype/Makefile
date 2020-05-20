SHELL := /bin/bash
.DEFAULT_GOAL := help

DIST_DIR ?= $(CURDIR)/dist
CHART_DIR ?= $(CURDIR)
TMPDIR ?= /tmp
HELM_REPO ?= $(CURDIR)/repo
LINT_CMD ?= ct lint --config=lint/ct.yaml --lint-conf lint/lintconf.yaml --chart-yaml-schema lint/chart_schema.yaml
PROJECT ?= github.com/zloeber/archetype
CHART ?= $(shell basename "$(CURDIR)")

.PHONY: help
help: ## Help
	@grep --no-filename -E '^[a-zA-Z_%/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: clean test build deploy ## clean, test, build, and deploy

test: lint unit-test ## lint and unit-test

lint: ## Run ct against chart
	@echo "== Linting Chart..."
	$(LINT_CMD)
	@echo "== Linting Finished"

unit-test: helm-unittest ## Execute Unit Testing
	@echo "== Unit Testing Chart..."
	@helm unittest --color --update-snapshot ./traefik
	@echo "== Unit Tests Finished..."

build: global-requirements $(DIST_DIR) ## Generates an artefact containing the Helm Chart in the distribution directory
	@echo "== Building Chart..."
	@helm package $(CHART_DIR) --destination=$(DIST_DIR)
	@echo "== Building Finished"

deploy: global-requirements $(DIST_DIR) $(HELM_REPO) ## Prepare the Helm repository with the latest packaged charts
	@echo "== Deploying Chart..."
	@cp $(DIST_DIR)/*tgz $(HELM_REPO)/
	@helm repo index --merge $(HELM_REPO)/index.yaml --url https://$(PROJECT)/ $(HELM_REPO)
	@echo "== Deploying Finished"

# Cleanup leftovers and distribution dir
clean:
	@echo "== Cleaning..."
	@rm -rf $(DIST_DIR)
	@rm -rf $(HELM_REPO)
	@echo "== Cleaning Finished"

################################## Technical targets

$(DIST_DIR):
	@mkdir -p $(DIST_DIR)

## This directory is git-ignored for now,
## and should become a worktree on the branch gh-pages in the future
$(HELM_REPO):
	@mkdir -p $(HELM_REPO)

global-requirements:
	@echo "== Checking global requirements..."
	@command -v helm >/dev/null || ( echo "ERROR: Helm binary not found. Exiting." && exit 1)
	@echo "== Global requirements are met."

lint-requirements: global-requirements
	@echo "== Checking requirements for linting..."
	@command -v ct >/dev/null || ( echo "ERROR: ct binary not found. Exiting." && exit 1)
#	@command -v yamale >/dev/null || ( echo "ERROR: yamale binary not found. Exiting." && exit 1)
#	@command -v yamllint >/dev/null || ( echo "ERROR: yamllint binary not found. Exiting." && exit 1)
#	@command -v kubectl >/dev/null || ( echo "ERROR: kubectl binary not found. Exiting." && exit 1)
	@echo "== Requirements for linting are met."

helm-unittest: global-requirements
	@echo "== Checking that plugin helm-unittest is available..."
	@helm plugin list 2>/dev/null | grep unittest >/dev/null || helm plugin install https://github.com/rancher/helm-unittest --debug
	@echo "== plugin helm-unittest is ready"

.PHONY: all global-requirements lint-requirements helm-unittest lint build deploy clean

.PHONY: show
show: ## Show env vars
	@echo "PROJECT: $(PROJECT)"
	@echo "CHART: $(CHART)"
	@echo "DIST_DIR: $(DIST_DIR)"
	@echo "CHART_DIR: $(CHART_DIR)"
	@echo "HELM_REPO: $(HELM_REPO)"
	@echo "LINT_CMD: $(LINT_CMD)"

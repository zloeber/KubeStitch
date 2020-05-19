SHELL := /bin/bash
.DEFAULT_GOAL := help
ROOT_PATH := $(abspath $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))
CONFIG_PATH := $(ROOT_PATH)/config
BIN_PATH := $(ROOT_PATH)/.local/bin
INSTALL_PATH := $(BIN_PATH)
TEMP_PATH := $(ROOT_PATH)/.local/tmp
APP_PATH := $(ROOT_PATH)/.local/apps
SCRIPT_PATH ?= $(ROOT_PATH)/scripts
DEPLOY_PATH ?= $(ROOT_PATH)/deploy
ENVIRONMENT ?= default
PROFILE ?= default

yq := $(BIN_PATH)/yq
jq := $(BIN_PATH)/jq

# Import target deployment env vars
ENVIRONMENT_VARS ?= $(CONFIG_PATH)/profile.$(PROFILE).env
ifneq (,$(wildcard $(ENVIRONMENT_VARS)))
include ${ENVIRONMENT_VARS}
export $(shell sed 's/=.*//' ${ENVIRONMENT_VARS})
endif

## List of sane defaults for local makefile building/testing
# Note: all values in here should be ?= in case they are already set upstream
CLOUD ?= local
KUBE_PROVIDER ?= kind
CLUSTER ?= cicd
KUBE_VERSION ?= 1.18.0
DOCKER_PROVIDER ?= dockerhub
ADDITIONAL_TASKSETS ?=
TASKSETS := cluster.$(KUBE_PROVIDER) common kube helm $(ADDITIONAL_TASKSETS)
DEPTASKS := $(foreach taskset, $(TASKSETS), $(addprefix .deps/, $(taskset)))
INCLUDES := $(foreach taskset, $(TASKSETS), $(addprefix $(ROOT_PATH)/inc/makefile., $(taskset)))

-include $(INCLUDES)

.PHONY: .githubapps
.githubapps: ## Install githubapp (ghr-installer)
ifeq (,$(wildcard $(APP_PATH)/githubapp))
	@rm -rf $(APP_PATH)
	@mkdir -p $(APP_PATH)
	@git clone https://github.com/zloeber/ghr-installer $(APP_PATH)/githubapp
endif

.PHONY: deps
deps: .githubapps $(DEPTASKS) .dep/yq .dep/jq ## Install general dependencies
	@mkdir -p $(TEMP_PATH)

.PHONY: .dep/yq
.dep/yq: ## Install yq
ifeq (,$(wildcard $(yq)))
	@$(MAKE) --no-print-directory -C $(APP_PATH)/githubapp auto mikefarah/yq INSTALL_PATH=$(BIN_PATH)
endif

.PHONY: .dep/jq
.dep/jq: ## Install jq
ifeq (,$(wildcard $(jq)))
	@$(MAKE) --no-print-directory -C $(APP_PATH)/githubapp install jq INSTALL_PATH=$(BIN_PATH)
endif

.PHONY: clean
clean: ## Remove downloaded dependencies
	rm -rf $(APP_PATH)/githubapp
	rm $(INSTALL_PATH)/*

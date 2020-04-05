# CICD Helper Tool
SHELL:=/bin/bash
.DEFAULT_GOAL:=help
.PHONY: help init deps tiller/start tiller/stop tiller/restart apply add sync diff test remove reload scorch template script list .init context

CURRENT_FOLDER=$(shell basename "$$(pwd)")
ROOT_PATH:=$(abspath $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))
DEPLOY_PATH:=$(ROOT_PATH)/deploy
SCRIPT_PATH ?= ${ROOT_PATH}/scripts
BIN_PATH ?= $(ROOT_PATH)/.local/bin

## Binary paths stay local to the project
export PACKAGES_PATH ?= $(ROOT_PATH)/.local/packages
export INSTALL_PATH ?= $(BIN_PATH)

## Other important defaults
TARGET ?= cicd
CLOUD ?= k3s
TEAM ?= team1
HELMFILE_PATH ?= ${ROOT_PATH}/helmfiles
HELMFILE_TARGET ?=

## Load Target Environment Parameter Files
#  1. Globals
#  2. Team - common
#  3. Target - common
#  4. Target - team
ENV_GLOBALS:=${ROOT_PATH}/globals.env
include ${ENV_GLOBALS}
export $(shell sed 's/=.*//' ${ENV_GLOBALS})

ENV_TEAM_COMMON=${ROOT_PATH}/teams/${TEAM}.env
ifneq (,$(wildcard $(ENV_TEAM_COMMON)))
include ${ENV_TEAM_COMMON}
export $(shell sed 's/=.*//' ${ENV_TEAM_COMMON})
endif

ENV_TARGET_COMMON=${ROOT_PATH}/targets/${TARGET}.env
include ${ENV_TARGET_COMMON}
export $(shell sed 's/=.*//' ${ENV_TARGET_COMMON})

ENV_CLOUD=${ROOT_PATH}/targets/cloud.${CLOUD}.env
ifneq (,$(wildcard $(ENV_CLOUD)))
include ${ENV_CLOUD}
export $(shell sed 's/=.*//' ${ENV_CLOUD})
endif

ENV_TARGET_TEAM=${ROOT_PATH}/targets/${TARGET}.${TEAM}.env
ifneq (,$(wildcard $(ENV_TARGET_TEAM)))
include ${ENV_TARGET_TEAM}
export $(shell sed 's/=.*//' ${ENV_TARGET_TEAM})
endif

ENV_OVERRIDES=${ROOT_PATH}/overrides.env
ifneq (,$(wildcard $(ENV_OVERRIDES)))
include ${ENV_OVERRIDES}
export $(shell sed 's/=.*//' ${ENV_OVERRIDES})
endif

## Load Application deployment parameters (if exists)
#  1. App - defaults
#  2. APP - Target
ENV_APP_COMMON=${ROOT_PATH}/apps/${APP}.env
ifneq (,$(wildcard $(ENV_APP_COMMON)))
include ${ENV_APP_COMMON}
export $(shell sed 's/=.*//' ${ENV_APP_COMMON})
endif

ENV_APP_TARGET=${ROOT_PATH}/apps/${APP}.${TARGET}.env
ifneq (,$(wildcard $(ENV_APP_TARGET)))
include ${ENV_APP_TARGET}
export $(shell sed 's/=.*//' ${ENV_APP_TARGET})
endif

## Sane defaults
STACK ?= cluster.${TARGET}
HELM_HOME ?= $(BIN_PATH)

## Used Binaries
helm ?= $(BIN_PATH)/helm
helmfile ?= $(BIN_PATH)/helmfile
jx ?= $(BIN_PATH)/jx
kind ?= $(BIN_PATH)/kind
kubectl ?= $(BIN_PATH)/kubectl
helmfile ?= $(BIN_PATH)/helmfile
gomplate ?= $(BIN_PATH)/gomplate
k3d ?= $(BIN_PATH)/k3d

-include $(ROOT_PATH)/inc/makefile.common
-include $(ROOT_PATH)/inc/makefile.packages
-include $(ROOT_PATH)/inc/makefile.kubernetes
-include $(ROOT_PATH)/inc/makefile.helm
-include $(ROOT_PATH)/inc/makefile.docker
-include $(ROOT_PATH)/inc/makefile.kind
-include $(ROOT_PATH)/inc/makefile.minikube
-include $(ROOT_PATH)/inc/makefile.k3s
-include $(ROOT_PATH)/inc/makefile.cicd
-include $(ROOT_PATH)/inc/makefile.show
-include $(ROOT_PATH)/inc/makefile.helmfile

ifeq ($(CLOUD),azure)
-include $(ROOT_PATH)/inc/makefile.az
endif

deps:
	$(MAKE) packages/init
	$(MAKE) packages/install kind
	$(MAKE) packages/install helm3
	$(MAKE) packages/install helmfile
	$(MAKE) packages/install kubectl
	$(MAKE) packages/install gomplate
	$(MAKE) packages/install k3d
	$(MAKE) packages/install jx
	$(MAKE) packages/install minikube
	$(MAKE) helm/plugins
	find . -name '*.sh' -print | xargs chmod +x
	@echo 'Initialization done!'

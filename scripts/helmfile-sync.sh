#!/bin/bash

helmfile --environment $ENVIRONMENT -f helmfiles/helmfile.cluster.$CLUSTER.yaml repos
helmfile --environment $ENVIRONMENT -f helmfiles/helmfile.cluster.$CLUSTER.yaml charts
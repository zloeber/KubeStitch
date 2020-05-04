## CICD Helper

This repo contains all manifests and templates required for a local kubernetes CICD environment. In some way's this is more like the playground of a madman's journey with Kubernetes all mashed up together with Makefiles and love.


## Goal

The goal of this repo is a CICD scratchpad to quickly bring up and tear down various CICD based local kubernetes environments for testing and vetting out solutions. I've made this somewhat modular as multiple kube clustering technologies can be swapped out relatively quickly and easily with a single environment variable file. 

## Requirements

Everything in this repo uses standard bash scripts and currently only supports Linux as a host OS. The following should be available on the system running these scripts.

- bash
- docker
- kvm or virtualbox (if using minikube)

Where required, stand-alone cli tools will be installed to a `./.local/` path within this folder to ensure total portability.

## Usage

```bash
# Show tasks
make

# Install dependencies
make deps

# Start a local kind cluster and create a local kube
make cluster/start

# Run tests on the cluster and watch the output with stern (press ctrl+c to exit)
make cluster/test

# Destroy the cluster you just created
make cluster/stop
```

You can do a default deployment of some helmfiles as well:

```bash
make deps cluster/start helmfile/sync
```

## Environments

Firstly, this was originally created to support multiple clusters and teams. I've since pared it back to just targeting a single 'environment'. You can see the current environment and some additional variables with `make show/env`. The base environment is 'default' which sources variables from `./config/default.env`. To create a whole new environment you can simply copy and modify the `./config/default.env` to `./config/myenvironment.env` then pass in `ENVIRONMENT=myenvironment` to all make commands.

The default environment is based on using kind. With another environment you can use k3d
```bash
## Launch a local k3d based kube cluster
make deps cluster/start ENVIRONMENT=k3d

## Launch a local kind based kube cluster
make deps cluster/start ENVIRONMENT=default

## Look at your first cluster
export KUBECONFIG=`make kube/config/file ENVIRONMENT=k3d`
kubectl get nodes

## And your second one too
export KUBECONFIG=`make kube/config/file ENVIRONMENT=default`
kubectl get nodes

## Destroy both clusters
make cluster/stop ENVIRONMENT=k3d
make cluster/stop  ## Default environment is 'default'
```

> **NOTE** While you can run multiple clusters at once that really wasn't what this project was meant for. It is best to run each cluster version separately.

## Example - Istio

Here is an example environment running istio on kind.

```bash
export ENVIRONMENT=istio
make deps cluster/start istio/deploy
export KUBECONFIG=`make kube/config/file`

# When done, run the following to destroy and get to your starting point again
make cluster/stop
unset ENVIRONMENT KUBECONFIG
```

## Additional Notes

- I've got a ton of extra 'stuff' in this repo that still needs to be cleaned out or redone as they technically serve no purpose (yet). Most of the essentials are in place for what I wanted to accomplish though.

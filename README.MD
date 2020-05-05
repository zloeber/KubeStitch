## CICD Helper

This repo contains all manifests and templates required for a local kubernetes CICD environment. In some way's this is more like the playground of a madman's journey with Kubernetes all mashed up together with Makefiles and love.

## Goal

The goal of this repo is a CICD scratchpad to quickly bring up and tear down various kubernetes environments for testing and vetting out solutions. I've made this somewhat modular so multiple Kubernetes clustering technologies can be swapped out relatively quickly and easily using a single environment variable file. For an example of what this might look like take a look at the Istio example in this document.

## Requirements

Everything in this repo uses standard bash scripts and currently only supports Linux as a host OS. The following should be available on the system running these scripts.

- bash
- docker

Where required, stand-alone cli tools will be installed to a `./.local/` path within this folder to ensure portability.

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

## Profiles

Firstly, this was originally created to support multiple clusters and teams. I've since pared it back to targeting profiles firstly, environments second. You can see the current profile (default) and environment (default) and some additional variables with `make show/env`. The profile is sources variables from `./config/${PROFILE}.env`. To create a whole new target environment you can simply copy and modify the `./config/default.env` to `./config/newprofile.env` then pass in `PROFILE=newprofile` to all make commands.

> **NOTE** `PROFILE` is for using different CICD configurations for testing purposes. `ENVIRONMENT` is what you would use to create helmfile deployment environment configurations. `ENVIRONMENT` is always 'default' unless manually passed in and is only used in the helmfile/* tasks.

The default profile is for a recent version of kubernetes running on kind. Another profile has been included to deploy k3d as well.

```bash
## Launch a local k3d based kube cluster
make deps cluster/start PROFILE=k3d

## Launch a local kind based kube cluster
make deps cluster/start PROFILE=default

## Look at your first cluster
export KUBECONFIG=`make kube/config/file PROFILE=k3d`
kubectl get nodes

## And your second one too
export KUBECONFIG=`make kube/config/file PROFILE=default`
kubectl get nodes

## Destroy both clusters
make cluster/stop PROFILE=k3d
make cluster/stop  ## Default environment is 'default'
```

> **NOTE** While you can run multiple clusters at once that really wasn't what this project was meant for and you will likely run into port or other conflicts. It is best to run each cluster then destroy it before changing and using another profile.

## Example - Istio

Here is an example environment running istio on a kind cluster. It includes;

- The deployment of metallb for the allocation of the loadbalancer element. 
- An additional plugin to include istio specific commands (found in inc/makefile.istio)
- An arkade based istio deployment
- An istioctl based istio operator deployment 
- An additional task to use istioctl to pull up any deployed istio dashboards

```bash
# Ensure we get the correct target
export PROFILE=istio

# Start the cluster
make deps cluster/start

# Install istio operator via istioctl using the default ISTIO_PROFILE of demo
make istio/deploy/operator

# Open the kiali dashboard (login: admin/admin) press ctrl+c when done
make istio/dashboard/kiali

# set the current kubectl config to the created config file for this profile and look at more stuff
export KUBECONFIG=`make kube/config/file`
kubectl get pods -n istio-system

# Deploy the bookinfo helmfile to create ingress rules for the app
make helmfile/sync STACK=bookinfo

# Go ahead and deploy the bookinfo example microservices app (https://istio.io/docs/examples/microservices-istio/bookinfo-kubernetes/)
kubectl label namespace default istio-injection=enabled
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/bookinfo/platform/kube/bookinfo.yaml

# Start the local dns forwarding to access the created resources without using kube proxy
make istio/start/dnsforward

# Destroy the cluster
make cluster/stop
unset PROFILE KUBECONFIG
```

## Additional Notes

- I've got a ton of extra 'stuff' in this repo that still needs to be cleaned out or redone as they technically serve no purpose (yet). Most of the essentials are in place for what I wanted to accomplish though.
- MetalLB is used when a loadbalancer is required. Currently the deployment will use IP addresses between 172.17.0.100 and 172.17.0.110. This is the bridge IP subnet of docker on my workstation. You can modify this range in the config file within `./config/metallb-config.yaml`.
- I have begun the scaffolding of a multi-environment helmfile deployment in this repo as well. configuration for the default environment is in `config/environment.default.yaml`. If you want another target environment for helmfile copy this file, make your changes, then whenever you are using `helmfile/*` commands include ENVIRONMENT=`<yourenvironment>`

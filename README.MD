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

Firstly, this was originally created to support multiple clusters and teams. I've since pared it back to targeting profiles. This means all top level settings that you may want to overwrite are able to be put in one file: `./config/<profilename>.env`. You can see the current profile (default) and environment (default) and some additional variables with `make show/env`.  

To create a whole new target environment you can simply copy and modify the `./config/default.env` to `./config/<newprofile>.env` then pass in `PROFILE=<newprofile>` to all make commands (or export it at the start of your session).

> **NOTE** `PROFILE` is for using different CICD configurations such as using k3d vs. using kind. `ENVIRONMENT` is what you would use to create helmfile deployment environment configurations. `ENVIRONMENT` is always 'default' unless manually passed in and is only used in the helmfile/* tasks. You can set `ENVIRONMENT` within the profile definition as well. The istio example below does this.

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

- A separate 'istio' profile (`./config/istio.env`) with overrides to the 
- An additional plugin to include istio specific commands (found in inc/makefile.istio)
- An istioctl based istio operator deployment
- Some additional istio tasks for monitoring ingress and such
- A helmfile based deployment of bookinfo:
    - Not a bad example of converting a straight yaml file to helmfile using the raw chart as a crude shortcut)
    - Exhibits helmfile dependency chaining
    - Uses a local custom namespace chart to also enable the istio sidecar injection label

```bash
# Ensure we get the correct target
export PROFILE=istio

# Start the cluster
make deps cluster/start

# Install istio operator via istioctl using the ISTIO_PROFILE of demo
make istio/deploy/operator

# Deploy the bookinfo helmfile for the full deployment along with ingress
make helmfile/sync STACK=bookinfo

# Start another pod to do dns forwarding of the url for this and the default domain (int.micro.svc) to your cluster loadbalancer
make istio/start/dnsforward
```

At this point you should be able to go to the example bookinfo microservice deployment by visiting [http://bookinfo.int.micro.svc/productpage](http://bookinfo.int.micro.svc/productpage) from your local machine. There are more things you may want to do though:

```bash
# configure local kubectl to access your kind cluster
export KUBECONFIG=`make kube/config/file`

# view some stuff to validate
kubectl get pods -n istio-system

# Open the kiali dashboard (login: admin/admin) press ctrl+c when done
make istio/dashboard/kiali

# Stop forwarding DNS
make istio/stop/dnsforward

# Destroy the cluster, reset your env vars
make cluster/stop
unset PROFILE KUBECONFIG
```

## Additional Notes

- I've got a ton of extra 'stuff' in this repo that still needs to be cleaned out or redone as they technically serve no purpose in the context of this project yet.
- MetalLB is used when a loadbalancer is required. Currently the deployment will use IP addresses between 172.17.0.100 and 172.17.0.110. This is the bridge IP subnet of docker on my workstation. You can modify this range in the config file within `./config/metallb-config.yaml`.
- I have begun the scaffolding of a multi-environment helmfile deployment in this repo as well. configuration for the default environment is in `config/environment.default.yaml`. If you want another target environment for helmfile copy this file, make your changes, then whenever you are using `helmfile/*` commands include ENVIRONMENT=`<yourenvironment>`

## Links/Inspiration

[Istio Practice Deployment](https://github.com/RothAndrew/istio-practice/tree/master/eks)


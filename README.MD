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

This project was originally created to support multiple clusters and teams. I've since pulled it back to simply targeting 'profiles'. This means all top level settings that you may want to overwrite are able to be put in a single file: `./config/<profilename>.env`. You can see the current profile (default) and environment (default) and some additional variables with `make show/env`.  

To create a whole new target environment you can copy and modify the `./config/default.env` to `./config/<newprofile>.env` then pass in `PROFILE=<newprofile>` to all make commands (or export it at the start of your session). If you need a separate environment or helmfile cluster deployment then further files will need to be created to accommodate.

> **NOTE** `PROFILE` is for using different cluster types and configurations. Testing the same set of helm charts to both k3d and kind (or any other target for that matter) might be facilitated by using a profile. An `ENVIRONMENT` is what you would use to create helmfile deployment environment configuration. `ENVIRONMENT` is always 'default' unless manually passed in and is only used in the helmfile/* tasks. You can set `ENVIRONMENT` within the profile definition or overwrite it when calling the tasks via the command line. The istio example uses an Environment to define a set of istio specific helm settings to deploy.


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

### Profile - Kind (default)

**File:** ./config/default.env

This profile is what we use for default deployments. It includes;

- A 2 node kind cluster running
- Kubernetes 1.18.2
- The calico CNI
- MetalLB

### PROFILE - k3d

**File:** ./config/k3d.env

- A 2 node k3d cluster
- Kubernetes 1.18.3
- Builtin k3d loadbalancer

This is a k3d cluster that is similar to the kind environment

### PROFILE - Istio

**File:** ./config/istio.env

Here is an example environment running istio on a kind cluster. It includes;

- A separate 'istio' profile (`./config/istio.env`) 
- An additional plugin to include istio specific commands (found in inc/makefile.istio)
- An istioctl based istio operator deployment
- Some istio tasks for monitoring ingress and such
- A helmfile based deployment of bookinfo:
    - Not a bad example of converting a straight yaml file to helmfile using the raw chart (as a crude shortcut)
    - Exhibits helmfile dependency chaining
    - Uses a local custom namespace chart to also enable the istio sidecar injection label upon deployment

```bash
# Ensure we get the correct profile for the remaining commands
export PROFILE=istio

# Start the cluster
make deps cluster/start istio/deploy helmfile/sync STACK=bookinfo dnsforward/start
```

At this point you should be able to go to the example bookinfo microservice deployment by visiting [http://bookinfo.int.micro.svc/productpage](http://bookinfo.int.micro.svc/productpage) from your local machine. There are more things you may want to do though:

```bash
# configure local kubectl to access your kind cluster
export KUBECONFIG=`make kube/config/file`
kubectl get pods -n istio-system

make helmfile/sync STACK=istiodashboards
```

Open the kiali dashboard at [http://kiali.int.micro.svc](http://kiali.int.micro.svc) (login: admin/admin)

To clean things up;

```bash
make dnsforward/stop cluster/stop
unset PROFILE KUBECONFIG
```

If k3d is more your style then you can repeat this entire set of directions with another profile I setup and tested in a few minutes after doing this with kind. Just use the istio-k3d profile instead! Here is the short version of the above steps to start things.

```bash
make cluster/start istio/deploy istio/start/dnsforward helmfile/sync STACK=bookinfo PROFILE=istio-k3d
```

## Additional Notes

- The `cluster/start` tasks will always first try to destroy the cluster then start it again so there is no need to destroy things manually if you are testing out several changes.
- I've got a ton of extra 'stuff' in this repo that still needs to be cleaned out or redone as they technically serve no purpose in the context of this project yet.
- MetalLB is used when a loadbalancer is required. Currently the deployment will use IP addresses between 172.17.0.100 and 172.17.0.110. This is the bridge IP subnet of docker on my workstation. You can modify this range in the config file within `./config/metallb-config.yaml`.
- I have begun the scaffolding of a multi-environment helmfile deployment in this repo as well. configuration for the default environment is in `config/environment.default.yaml`. If you want another target environment for helmfile copy this file, make your changes, then whenever you are using `helmfile/*` commands include ENVIRONMENT=`<yourenvironment>`

## Links/Inspiration

[Istio Practice Deployment](https://github.com/RothAndrew/istio-practice/tree/master/eks)

[Fury Kubernetes Distribution](https://github.com/sighupio/fury-distribution)

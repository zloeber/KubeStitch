## CICD Helper

This repo contains all manifests and templates required for a local kubernetes CICD environment. In some way's this is more like the playground of a madman's journey with Kubernetes all mashed up together with Makefiles and love.

## Goal

The goal of this repo is a CICD scratchpad to quickly bring up and tear down various kubernetes environments for testing and vetting out solutions. I've made this somewhat modular so multiple Kubernetes clustering technologies can be swapped out relatively quickly and easily using a single environment variable file. To see what this might look like, explore the Istio example further down in this document.

## Requirements

Everything in this repo uses standard bash scripts and currently only supports Linux as a host OS. The following should be available on the system running these scripts.

- bash
- docker

Where required, stand-alone cli tools will be installed to a `./.local/` path within this folder to ensure portability.

## Usage

Standard usage is pretty simple. 

```bash
# Show tasks
make

# Install dependencies
make deps

# Start a local kind cluster and create a local kube
make cluster/start

# Run tests on the cluster and watch the output with stern (press ctrl+c to exit)
make cluster/test

# Perform a default deployment of helmfiles for the cluster definition
make helmfile/sync

# Destroy the cluster you just created
make cluster/stop
```

## Kube Clusters

Before going into profiles, it is important to be aware that each cluster that gets created will create its own configuration file within the `./.local/` path in the form of `kube.<clustername>.conf`. This ensures your personal user kubernetes configuration does not get polluted with testing cluster detritus. But this also means that, by default, you will not be able to interface with the cluster without some additional work. The simple way around this is to just point your 'KUBECONFIG' env var to the config file that gets generated. This can be done easily with the following command after the cluster has been created:

```bash
export KUBECONFIG=`make kube/config/file` 
```

You only need to do this once for any cluster you are working on (per console session). If you recreate the cluster in your journey (done easily via `make cluster/start`) this file may get recreated but it shouldn't matter so much.

If you are tinkering with multiple versions of Kubernetes, then it may be useful to also set an alias for the kubectl binary as well.

```bash
alias kube=$(pwd)/.local/bin/kubectl
```

If you are changing between versions of Kubernetes using this framework you will have to clear out the kubectl binary when changing versions (between cluster builds) with `make clean`. Just ensure you also rerun the deps task to get the correct kubectl binary version afterwards.

## Profiles

This project was originally created to support multiple clusters and teams. I've since pulled it back to simply targeting 'profiles'. This means all top level settings that you may want to overwrite are able to be put in a single file: `./config/<profilename>.env`. To see the current profile, helmfile environment, and some additional variables, use `make show`.  

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

### PROFILE - istio

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

### PROFILE - vault

**File:** ./config/vault.env

This is another proof of concept environment that spins up a kind cluster running Hashicorp vault with a consul backend. It also includes installation of some dependencies for testing things out as well as vault-sync to test out seeding a base deployment via cli. This is a work in progress on how one might use mostly declarative configuration for a vault integrated kubernetes cluster.

If you run this:

```bash
export PROFILE=vault
make deps cluster/start helmfile/sync dnsforward/start
```

Then you can access both [http://consul.int.micro.svc](http://consul.int.micro.svc) and [http://vault.int.micro.svc](http://vault.int.micro.svc) to immediately start exploring these cool products.

## Tasksets

Sometimes there are additional commands required to vet out a solution. To accommodate for this need, you can add a new makefile directly in the 'inc' folder as `./inc/makefile.<taskset>` and then add the `<taskset>` into your profile's `ADDITIONAL_TASKSETS` definition (space delimited if there is more than one). This will source in your new script tasks automatically only when the profile is used.

## Helmfile Environments

Configuration for the default helmfile environment is in `config/environment.default.yaml`. These values get sourced into the various helmfiles I am working with at the time. I'll add/remove/change these values as I please depending on the lab I'm working with at the time. The idea is that I can create new, non-local, environments from this and make simple changes to target them from a pipeline when the time comes.

To target another environment for helmfile follow a few extra steps.

1. copy/modify `config/environment.default.yaml` to `config/environment.<your_environment>.yaml`
2. Add the new environment name and have it point to the file you created in `config/environments.yaml`
3. Then whenever you are targeting a helmfile to the environment commands include `ENVIRONMENT=<your_environment>` ()

> **NOTE** I try to keep all settings in the default helmfile environment yaml definition with each helmfile 'stack' as its own section. This suits me. You can modify this but will also have to modify the helmfiles that use these yaml paths as well.

## Example Usage

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

- The `cluster/start` tasks will always first try to destroy the cluster before starting it.
- There is a ton of extra 'stuff' in this repo that still needs to be cleaned out or revisited, not all files serve a purpose (yet)
- Along the same lines as the prior statement, there are a ton eof 'helmfiles' in the helmfile/wip folder that worked with env vars at one point. I'll slowly move these out of wip when I'm able to do so or the need comes up.
- MetalLB is used when a loadbalancer is required. Currently the deployment will use IP addresses between 172.17.0.100 and 172.17.0.110. This is the bridge IP subnet of docker on my workstation. You can modify this range in the config file within `./deploy/metallb/metallb-config.yaml`.

## Links/Inspiration

[Istio Practice Deployment](https://github.com/RothAndrew/istio-practice/tree/master/eks)

[Fury Kubernetes Distribution](https://github.com/sighupio/fury-distribution) - The basic concept of 'stacks' that I have been putting together using helmfiles has been done in this distribution using kustomize instead. Inspiring work.

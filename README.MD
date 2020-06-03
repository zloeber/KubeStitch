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

Standard usage is pretty simple. After cloning this repo you can start a default kind cluster with one command:

```bash
make cluster
```

This aggregates several tasks which are broken down further below.

```bash
# Show tasks
make

# Install dependencies
make deps

# Start a local kind cluster and create a local kube
make cluster/start

# Run tests on the cluster and watch the output with stern (press ctrl+c to exit)
make cluster/test

# Perform a default deployment of helmfiles for the cluster defined in the profile (default: cicd)
make helmfile/sync

# Destroy the cluster you just created
make cluster/stop
```

## Clusters

Before going into profiles, it is important to be aware that each cluster that gets created will create its own configuration file within the `./.local/` path in the form of `kube.<clustername>.conf` unless `KUBE_CONFIG` is overwritten in the profile. This ensures your personal user kubernetes configuration does not get polluted with testing cluster detritus. But this also means that, by default, you will not be able to interface with the cluster without some additional work. The simple way around this is to just point your 'KUBECONFIG' env var to the config file that gets generated. This can be done easily with the following command after the cluster has been created:

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

This project was originally created to support multiple clusters and teams. I've since pulled it back to simply targeting 'profiles'. This means all top level settings that you may want to overwrite are able to be put in a single file: `./profiles/<profilename>.env`. To see the current profile, helmfile environment, and some additional variables, use `make show`.  

To create a whole new target environment you can copy and modify the `./profiles/default.env` to `./profiles/<newprofile>.env` then pass in `PROFILE=<newprofile>` to all make commands (or export it at the start of your session). If you need a separate environment or helmfile cluster deployment then further files will need to be created to accommodate.

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

### Profile - default

**File:** ./profiles/default.env

This profile is what we use for default deployments. It includes;

- A 2 node kind cluster running
- Kubernetes 1.18.2
- The calico CNI
- MetalLB

 After the cluster starts up and you run the `dnsforward/start` task the following urls will be available.
 
 - http://traefik.int.micro.svc

 ### Profile - monitoring

**File:** ./profiles/monitoring.env

This profile is the same as the default profile but allows for the prometheus operator to also be deployed. After the cluster starts up and you run the `dnsforward/start` task the following urls will be available.

- http://traefik.int.micro.svc
- http://grafana.int.micro.svc
- http://alertmanager.int.micro.svc
- http://prometheus.int.micro.svc

The grafana site default login is `admin/prom-operator`

### PROFILE - k3d

**File:** ./profiles/k3d.env

- A 2 node k3d cluster
- Kubernetes 1.18.3
- Builtin k3d loadbalancer

This is a k3d cluster that is similar to the kind environment

### PROFILE - istio

**File:** ./profiles/istio.env

Here is an example environment running istio on a kind cluster. It includes;

- A separate 'istio' profile (`./profiles/istio.env`) 
- An additional plugin to include istio specific commands (found in inc/makefile.istio)
- An istioctl based istio operator deployment
- Some istio tasks for monitoring ingress and such
- A helmfile based deployment of bookinfo:
    - Not a bad example of converting a straight yaml file to helmfile using the raw chart (as a crude shortcut)
    - Exhibits helmfile dependency chaining
    - Uses a local custom namespace chart to also enable the istio sidecar injection label upon deployment

### PROFILE - vault

**File:** ./profiles/vault.env

This is another proof of concept environment that spins up a kind cluster running Hashicorp vault with a consul backend. It also includes installation of some dependencies for testing things out as well as vault-sync to test out seeding a base deployment via cli. This is a work in progress on how one might use mostly declarative configuration for a vault integrated kubernetes cluster.

You can access both [http://consul.int.micro.svc](http://consul.int.micro.svc) and [http://vault.int.micro.svc](http://vault.int.micro.svc) to immediately start exploring these cool products after bringing up the cluster.

If you use this profile the vault service will be provisioned via a loadbalancer IP which can be accessed using the vault client and some environment variables. To export these variables into your session use the following command:

```bash
`make show/vault`
./.local/bin/vault status
```

### PROFILE - localstack

**File:** ./profiles/localstack.env

This profile is for setting up the venerable [localstack](https://github.com/localstack/localstack) AWS API simulation environment in kubernetes. The deployment was a 10 minute effort proof of concept done by converting the project's docker-compose file via kompose then plugging in the output into a custom helmfile.

This can be a great way to vet out terraform manifests or test out AWS based pipelines.

### PROFILE - argocd

**File:** ./profiles/argocd.env

Create a local argocd cluster for testing out GitOps. Includes customization to allow for helmfile use in the application definitions.

To access the GUI interface (https://argocd.int.micro.svc/) the default ID is `admin` and the password can be retrieved by running `make argocd/get/password` (typically ends up being the argocd-server pod name)

**NOTE:** I'm still working on the helmfile argocd repository task runner. This is just a base environment and nothing more.

### PROFILE - homeassist

Performs a local install/uninstall of a single node k3s cluster for use in a bare metal home assistant deployment. This assumes the local machine is Linux ready and uses sudo rights to setup the service. This profile is custom built for my own environment which includes an NFS storage backend and should not be used without modifications.

**File:** ./profiles/homeassist.env

**NOTE:** To do the same deployment locally via kind use the 'kind_homeassist' profile instead.

## Tasksets

Sometimes there are additional commands required to vet out a particular solution. To accommodate for this need, you can add a new makefile directly in the 'inc' folder as `./inc/makefile.<taskset>` and then add the `<taskset>` into your profile's `ADDITIONAL_TASKSETS` definition (space delimited if there is more than one). This will source in your new script tasks automatically only when the profile is used.

You can see the tasksets which are available within the 'inc' folder of this repo. Thus far there are a few default tasksets and these additional ones:

- vault
- consul
- argocd
- arkade
- fury
- gitlab
- istio
- lens
- metallb
- tekton
- terraform
- k9s
- prometheus
- docker

Not all of these are useful for every scenario so they simply don't get loaded (otherwise `make help` would be WAY too long of a list!). The follow tasksets are loaded every time though:

- helm
- kube
- common

### Provider Tasksets

A provider taskset is special as it is a specific taskset for provisioning kubernetes clusters. These are in the same location as the other tasksets but with a different naming convention, `./inc/makefile.provider.<taskset>`. Only one provider taskset should be loaded at a time. Thus far kind and k3d are the most reliable and tested provider tasksets but I also include a minikube provider from earlier testing as well as the k3s taskset for my home server deployment.

> **NOTE:** I abandoned minikube earlier on for a number of reasons but it would be feasible to fix this up and use minikube as well if that's your thing.

If you add a new provider ensure that the 'cluster/*' tasks exist to bring up and tear down clusters. I'd model them against the existing kind or k3d provider tasksets.

## Helmfile

I use helmfile extensively to declaratively stitch together my deployments from other helm charts, my own monochart (called archetype), and the raw helm chart. Helmfile uses 'environments' to help breakdown multiple configuration paths.

### Helmfile Environments

The per-environment values files are defined in `config/environments.yaml`. This just points to the individual values files that reside in ther own per-environment folder. This environment folder also includes relevant helm repositories and helm default values. These values get sourced into the various helmfiles using a common block at the top of each helmfile. 

The idea is that I can create new environments from copying this folder and make simple changes to target them from a pipeline when the time comes.

To target another environment for helmfile follow a few extra steps.

1. Modify `config/environments.yaml` to add a new environment and values file
2. Copy the `config/default` folder to `config/<your_environment>`
3. Update any files in `config/<your_environment>` to suit your needs
3. Then whenever you are targeting a helmfile to the environment commands include `ENVIRONMENT=<your_environment>` (or set ENVIRONMENT in your top level profile)

I try to keep all settings in the default helmfile environment yaml definition and overwrite their installation in the environment level file when I need to do so.
In this example, I disable monitoring elements from being deployed to the default environment even though the same setting in the `./config/default/values.yaml` file is enabled.

```yaml
# ./config/environments.yaml
environments:
  default:
    values:
    - ../config/default/values.yaml
    - prometheusoperator:
        enabled: false
```

As you can see, I purposefully set the prometheus operator deployment as disabled in the default environment. This is because one usually does not want an entire monitoring environment when doing local testing. But many helmfile stacks include monitors that I may otherwise need to deploy that have dependencies upon CRDs of the Prometheus Operator. To work around this chicken/egg scenario we simply disable the monitoring stack at the environment level and use that variable when deploying monitoring elements in the various stacks. The same type of logic is done with the 'ingress' stack so we can deploy several stacks and simply not deploy ingress by ensuring that ingress.enabled=false if we so desire.

> **NOTE:** The approach I take is that all stacks are default enabled unless the environment overrides say otherwise. This does not mean that all stacks are deployed by default, this is what the cluster helmfiles are for. But we can add/remove individual stacks this way.

This effectively makes the `../config/default/values.yaml` our default settings with anything under `./config/environments.yaml` being the overrides. I source these settings in for all my helmfiles which allows me to update helm chart versions and sources from one values file. If I want to test a new chart I can create another environment with the value being overwritten in `./config/environments.yaml` while retaining all other chart settings.

> **NOTE:** In the past I've utilized many environment variables for these kinds of settings. While it is tempting to do so I recommend against this style of chart authoring as it makes for more complex pipelines and a less declarative approach to deployments.


### Helmfile Stacks

For lack of better terminology I use 'stack' to define a set of helm charts that I've stitched together as a deployable unit. Typically this is a handful of charts all targeting a single namespace by the same name. I attempt to create helmfiles in a manner which can be deployed individually but there may be some cross dependencies for more complex stacks (like if I use cert manager CRDs for instance). 

A set of stacks can be applied, in order, via a single helmfile. This is how I deploy whole cluster configurations declaratively. Below you can see the default cicd cluster helmfile. As it is simply another helmfile we keep the cluster helmfile definitions right alongside the rest of the stacks.

```bash
#/helmfiles/helmfile.cluster.cicd.yaml
---
bases:
- ../config/environments.yaml
---

helmfiles:
- ../helmfiles/helmfile.traefik.yaml
- ../helmfiles/helmfile.cert-manager.yaml
- ../helmfiles/helmfile.security.yaml
- ../helmfiles/helmfile.metricsserver.yaml
```

What makes this fun is that I have a whole other profile called 'vault' that creates its own cluster (aptly named 'vault') that I put together simply for the convenience of bringing up a full cluster configured with consul and vault in a single command. But I don't need to use the vault profile to run consul and vault. We can also add individual helmfile stacks or the entire cluster helmfile stack definition at any time to any cluster while in any profile.

```bash
unset PROFILE   # Use the default profile
make deps cluster/start helmfile/sync # Setup a default cluster
make helmfile/sync STACK=consul # Install only the consul stack
make helmfile/sync STACK=cluster.vault # Or apply the cluster stack entirely outside of the vault profile (note that consul is already applied and will not be applied again even though it is listed in the cluster.vault helmfile)
make helmfile/destroy STACK=consul # Now remove just consul for the hell of it
```

This is a powerful way to quickly work on various deployments and allows for layering of stacks to get the results you are looking for in an iterative manner.

> **NOTE** Sometimes you may have to wait for the initial cluster to fully come up before running the helmfile/apply for the entire cluster.


# Examples

Here are a few example use cases worth looking over.

## Example 1

Here is an example of using a profile to start up a local istio cluster. Istio has a moderately more complex deployment path than a standard helm chart so this is a good example for showing how CICDHelper can be flexible.

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

## Example 2

This is a somewhat unique example. Basically I used this framework for a bare metal k3s cluster at home for home assistant. I created another kubernetes provider specifically for k3s (`inc/makefile.cluster.k3s`) along with a profile to use it (`profiles/profile.homeassist.env`). With this profile and provider I overwrite the default location of the KUBE_CONFIG so that after installation of the cluster elements the config is automatically updated for my standard account. This particular provider does require sudo rights.

A neat trick I use here is to set 'CLUSTER' to 'haas' in the profile and create a helmfile.cluster.haas.yaml file for use in deploying all stacks to this deployment even though it is not local.

```bash
export PROFILE=homeassist
make cluster
```

The k3s provider I created specifically disables many of the default deployment settings of k8s, specifically the default 'local-path' storage provider. I later use NFS mounts in my home setup using the nfs-client-provider. This gets installed via helmfile like 99% of hte cluster configuration.

While I was testing this out on an old Shuttle PC I found out that some memory sticks were bad. As I was running memtest86+ against the server (which takes forever and a day) I quickly setup another profile called 'kind_homeassist' so I could continue vetting out my kubernetes deployment stacks. In a few minutes I had the same deployment via the kind provider up and running.

```bash
export PROFILE=kind_homeassist
make cluster
make helmfile/sync STACK=homeassistant
```

You may notice that I use the cicd cluster for the local kind install as I know it works locally and since I'm not using nfs mounts or anything like that in my docker based cluster it makes sense for me to use a default baseline cluster and simply manually add the stacks in that I'm testing afterwards.

Because I'm using some localized IP addresses for both the nfs provisioner chart and traefik, I created another helmfile profile in 'config/environments.yaml' with these override settings in place. I do not yet know how to extract the extrapolated values yaml from helmfile so for now I also have to put these values in the 'config/homeassist/values.yaml' file for the Metallb deployment scripts to locate and for dnsforward tasks to use.

> **NOTE**: In this setup I run the CICDHelper from my server then access it remotely via kubectl. To do this I have to copy over the config file that gets generated to my workstation `scp zloeber@servername:~/.kube/config ~/.kube/config ` then edit it to replace 127.0.0.1 with the IP address of the server.

## Secrets

Any secrets should be put into your environment for use in tasksets that require them. For this I personally use direnv with a local .envrc file. 

```bash
## Example direnv file for exporting a gitlab token used to login to the gitlab cli
export GITLAB_TOKEN=<your token>
```

## Lens (GUI Console)

Lens is a particularly useful GUI app for rucking about in Kubernetes. It is also cross-platform. If you are running a linux host you can use this framework to automatically download the app and access clusters with it. I've added some scriptwork to automatically clear the lens clusters and add new configuration in a few commands. Here is how it works.

> **NOTE** the lens taskset is targeted towards linux hosts. For a cross-platform console dashboard you can also use the `make k9s` task!

```bash
# First download lens and run it at least once
make deps lens

# Then, assuming your cluster has been started (make cluster/start) you can add it to the lens cluster store/config. By default, this will first clear any added clusters in the configuration (localized in the ./.local/Lens/lens-cluster-store.json file)
make lens/addcluster
```

That is it, then start lens again and your running cluster will be the first one in the list (at the upper left).

```bash
make lens
```

# Additional Info

- `cluster/start` will always first try to destroy the cluster before starting it.
- `cluster/start` always spins up a bare deployment (no helmfile stacks applied)
- `helmfile/sync` will default to `STACK=cluster.$(CLUSTER)`
- The above information means `make cluster/start helmfile/sync` will always recreate a cluster from scratch then install the default cluster helmfile stack of charts for the current profile's cluster.
- All of the commands above are condensed into `make cluster`
- There is a ton of extra 'stuff' in this repo that still needs to be cleaned out or revisited, not all files serve a purpose (yet)
- Along the same lines as the prior statement, there are a ton eof 'helmfiles' in the helmfile/wip folder that worked with env vars at one point. I'll slowly move these out of wip when I'm able to do so or the need comes up.
- MetalLB is used when a loadbalancer is required.
- ~~Currently the loadbalancer deployment will use IP addresses between 172.17.0.100 and 172.17.0.110. This is the bridge IP subnet of docker on my workstation. You can modify this range in the config file within `./deploy/metallb/metallb-config.yaml`.~~ This is/was only for kind and is now automatically determined when metallb is deployed to the cluster. You can still override this in the `./config/environment.default.yaml` file by adding `stacks.ingress.internalLBSubnet` and assigning it a CIDR subnet instead. Otherwise it grabs the `DOCKER_NETWORK` subnet and replaces the last digits with 1.0/24 (in my case it now ends up being 172.21.1.0/24 since I kept screwing around with the bridge network...whoops.)
- Currently I source in all used repositories regardless if they are used or not, this slows down initial syncing and probably can be improved upon somehow.
- The `dnsforward/*` tasks are a bit janky as it is really hard to account for all possible scenarios. Generically, only use dnsforward tasks for local cluster testing (and make any additional forwarding updates/changes via the web interface if the logic is not working for you).

## Why Makefiles?

Great question! One which I sometimes struggle to answer. There are dozens of other taskers out there but make is probably one of the older ones that is well supported across a number of different systems. I personally use it when I might use bash scripts otherwise. It allows me to quickly view the commands being run (if I've not purposefully hidden them with a well placed prepended @ symbol). Plus I'm sort of used to slinging makefiles so why not? Besides, most repos worth their salt have at least one of these to bootstrap things in some manner so it doesn't hurt to get to know them a bit I'd say.

> **NOTE** If you are copying task definitions out for stand alone scripts remember to replace '$$' for '$' where ever you see them.

# Resources

[Helmfile](https://github.com/roboll/helmfile) - The ultimate helm chart stitcher

[My Archetype Chart](https://github.com/zloeber/archetype-chart) - I use this quite a bit for standardized ingress among other things

[Manage Helm Charts With Helmfile](https://www.arthurkoziel.com/managing-helm-charts-with-helmfile/) - Good article on some techniques to implement DRY helmfile deployments

[Helm Secrets Plugin](https://github.com/zendesk/helm-secrets) - Helm plugin for secrets management

[Istio Practice Deployment](https://github.com/RothAndrew/istio-practice/tree/master/eks) - Inspired me to finish this framework

[Fury Kubernetes Distribution](https://github.com/sighupio/fury-distribution) - The basic concept of 'stacks' that I have been putting together using helmfiles has been done in this distribution using kustomize instead. Inspiring work but far too difficult to modify and use for rapid stack stitching from my experience.

[CloudPosse's Helmfiles](https://github.com/cloudposse/helmfiles) - A very impressive and well written set of helmfiles. Inspirational and if I'm honest, better than my own charts.

[MetalLB](https://metallb.universe.tf/) - The software loadbalancer used in several of the cluster profiles
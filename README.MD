## CICD Helper

This repo contains all manifests and templates required for a local kubernetes CICD environment. In some way's this is more like the playground of a madman's journey with Kubernetes all mashed up together with Makefiles and love. 

## Requirements

This is all run via standard bash scripts and some other standard cli tooling. I put this all together Ubuntu derivatives running docker. Generally though the following will be required:
- bash
- docker
- kvm or virtualbox (if using minikube)

## Usage

A handful of stand-alone binaries will be required for you to use this project. They get installed within this folder automatically with the following command:

```bash
make deps
```

```bash
# Show tasks
make

# Start a local minikube cluster called 'cicd'
make cicd/start

# Destroy the cluster you just created
make cicd/stop

## Same as above, but use kind instead
make cicd/start CLOUD=kind
make cicd/stop CLOUD=kind
```

## Env Var (order of operation)

All settings are pulled in from a handful of .env files. These are done in a specific order to allow for multiple cicd environments that may be required for handling multiple teams and projects. These are loaded, in order as follows:

1. globals.env - This is a good place for global default values as it is the lowest precedence)
2. {TARGET}.env - By default this will be cicd.env. 
2. cloud.{CLOUD}.env - By default this will be cloud.minikube.env
3. {TARGET}.{TEAM}.env - By default this will be cicd.team1.env

The Makefile will allow for overrides of the standard variables which can, in turn, steer the entire deployment path accordingly.

## Notes

- Ingress is setup using metallb as the loadbalancer using one of the docker network IPS that was available on my system at the time (172.17.255.1)


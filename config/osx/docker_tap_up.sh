#!/bin/bash

set -o nounset
set -o errexit

## Create a temporary cluster to ensure that the 'kind' docker network exists
# kind create cluster --name tempcluster

# Local and host tap interfaces
TAP_INT=$(ifconfig | grep "^tap.*$" | cut -d':' -f1)
hostTapInterface=eth1

# Local and host gateway addresses
localGateway='10.0.75.1/30'
hostGateway='10.0.75.2'
hostNetmask='255.255.255.252'

#hostGateway=$(docker network inspect kind | jq '.[0].IPAM.Config[0].Gateway' -r)

# ## Delete temporary kind cluster
# kind delete cluster --name tempcluster

# Startup local and host tuntap interfaces
sudo ifconfig $TAP_INT $localGateway up
docker run --rm --privileged --net=host --pid=host alpine ifconfig $hostTapInterface $hostGateway netmask $hostNetmask up

echo "Tap interface configuration:"
ifconfig $TAP_INT

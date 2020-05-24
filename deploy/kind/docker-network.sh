#!/bin/bash
## Create a kind network in bridge mode
docker network create -d bridge \
--opt=com.docker.network.bridge.enable_icc=true \
--opt=com.docker.network.bridge.enable_ip_masquerade=true \
--opt=com.docker.network.bridge.host_binding_ipv4=0.0.0.0 \
--opt=com.docker.network.bridge.name=kind0 \
--opt=com.docker.network.driver.mtu=1500 \
kind
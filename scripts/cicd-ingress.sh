#!/usr/bin/env bash
## Use socat to forward ports to cicd deployment

KINDCLUSTER=${KINDCLUSTER:-"cicd"}
NAMESPACE="ingress-int"
SERVICE=${SERVICE:-"nginx-ingress-controller"}
KINDCLUSTERIP=$(kubectl get service -n ${NAMESPACE} ${SERVICE} -o=jsonpath="{.spec.clusterIP}")
for port in 80 443
do
    node_port=$(kubectl get service -n ${NAMESPACE} ${SERVICE} -o=jsonpath="{.spec.ports[?(@.port == ${port})].nodePort}")
    docker run -d --rm \
      --name ${KINDCLUSTER}-kind-proxy-${port} \
      --publish 127.0.0.1:${port}:${port} \
      --link ${KINDCLUSTER}-control-plane:target \
      alpine/socat -dd \
      tcp-listen:${port},fork,reuseaddr tcp-connect:target:${node_port}
      #tcp-listen:${port},fork TCP:${KINDCLUSTERIP}:${node_port}

    # docker run -d --name ${KINDCLUSTER}-kind-proxy-${port} \
    #   --publish 127.0.0.1:${port}:${port} \
    #   --link ${KINDCLUSTER}-control-plane:target \
    #   alpine/socat -dd \
    #   tcp-listen:${port},fork,reuseaddr tcp-connect:target:${node_port}
done
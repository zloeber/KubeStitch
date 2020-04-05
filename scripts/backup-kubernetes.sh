#!/bin/bash

RESSOURCE_IGNORE="^(namespaces|pods|events|nodes|clusters|storageclasses|thirdpartyresources|clusterrolebindings|clusterroles|componentstatuses|persistentvolumes)$"

echo "-> Getting namespaces ..."
kubectl get --export -o=json ns | \
jq '.items[] |
	select(.metadata.name!="kube-system") |
	select(.metadata.name!="default") |
	del(.status,
        .metadata.uid,
        .metadata.selfLink,
        .metadata.resourceVersion,
        .metadata.creationTimestamp,
        .metadata.generation
    )' > ./backup-namespaces.json
echo "=> Namespaces saved."

echo "-> Saving every namespaced objects"
for ns in $(jq -r '.metadata.name' < ./backup-namespaces.json); do
    echo "--> Currently saving namespace: $ns"
	mkdir "backup-$ns"
	for ressource in $(kubectl get --help 2>&1 | grep '  \* ' | sed 1d | awk '{ print $2}' | tr "\n" ' '); do
		if [[ "$ressource" =~ $RESSOURCE_IGNORE ]]; then
			continue
		fi
		echo "---> Saving ressource: $ressource"
        EXPORT="$(kubectl --namespace="${ns}" get --export -o=json "$ressource" | \
			jq '.items[] |
				select(.type!="kubernetes.io/service-account-token") |
                del(
                    .spec.clusterIP,
                    .metadata.uid,
                    .metadata.selfLink,
                    .metadata.resourceVersion,
                    .metadata.creationTimestamp,
                    .metadata.generation,
                    .status,
                    .spec.template.spec.securityContext,
                    .spec.template.spec.dnsPolicy,
                    .spec.template.spec.terminationGracePeriodSeconds,
                    .spec.template.spec.restartPolicy
                )')"
		if [ -n "$EXPORT" ]; then
        	echo "$EXPORT" >> "./backup-$ns/$ressource.json"
	    fi
		echo "---> Saved ressource: $ressource"
	done
	echo "--> Namespace saved: $ns"
done
echo "=> Namespaced objects saved."

echo "-> Saving non-namespaced objects..."
kubectl --namespace="${ns}" get --export -o=json clusterrolebindings,clusterroles,componentstatuses,storageclasses,thirdpartyresources,persistentvolumes | \
jq '.items[] |
	select(.type!="kubernetes.io/service-account-token") |
	del(
		.spec.clusterIP,
		.metadata.uid,
		.metadata.selfLink,
		.metadata.resourceVersion,
		.metadata.creationTimestamp,
		.metadata.generation,
		.status,
		.spec.template.spec.securityContext,
		.spec.template.spec.dnsPolicy,
		.spec.template.spec.terminationGracePeriodSeconds,
		.spec.template.spec.restartPolicy
	)' >> "./backup-non-namespaced.json"
echo "=> Saved non-namespaced objects."

echo "Completed."
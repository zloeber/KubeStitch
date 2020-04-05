#!/bin/bash
# Interactively create an Azure Service Principal for any of your subscriptions
# Author: Bruno Medina (@brusmx)
# Requirements:
# - Azure Cli 2.0

echo "Obtain a Service Principal for one of your Azure Subscriptions."
export ROLE="Contributor"
export DEFAULT_ACCOUNT=`az account show -o tsv`

DEFAULT_ACCOUNT_ID=$(printf %s "$DEFAULT_ACCOUNT" | cut -f2)

if [ ! -z "$DEFAULT_ACCOUNT_ID" ]; then
    export DEFAULT_ACCOUNT_NAME=`printf %s "$DEFAULT_ACCOUNT" | cut -f4`
    echo "Current subscription (default): \"${DEFAULT_ACCOUNT_NAME}\" (${DEFAULT_ACCOUNT_ID})"
    echo ""
    export ACCOUNT_LIST=`az account list -o tsv`
    export ACCOUNT_LIST_ID=`printf %s "$ACCOUNT_LIST" |  cut -f2`
    export ACCOUNT_LIST_NAMES=`echo $ACCOUNT_LIST |  cut -f4 -d$' '`
    export ACCOUNT_LIST_SIZE=`echo "$ACCOUNT_LIST" | wc -l`
    echo "Found $ACCOUNT_LIST_SIZE enabled subscription(s) in your Azure Account:"
    echo ""
    export COUNT=1
    IFS=$'\n'
    set -f
    for line in $(printf %s "$ACCOUNT_LIST"); do
        echo "${COUNT}) $(printf %s "$line" | cut -f4 ) || ($(echo $line | cut -f2 ))"
        ((COUNT++))
    done
    set +f
    unset IFS
    echo ""
    echo "Select a subscription (1-`expr ${ACCOUNT_LIST_SIZE}`) or press [enter] to continue with the (default) one:"
    read selection
    echo "Your selection is ${selection}"
    if [ -z "$selection" ]; then
        export AZURE_SUBSCRIPTION_ID=$DEFAULT_ACCOUNT_ID
    elif [ "$selection" -gt 0 ] && [ "$selection" -le "${ACCOUNT_LIST_SIZE}" ]; then
        export AZURE_SUBSCRIPTION_ID=$(sed -n ${selection}p <<< "$ACCOUNT_LIST_ID")
    else
        echo "Incorrect selection, Service Principal not created"
        exit 1
    fi
        echo "Selected ${AZURE_SUBSCRIPTION_ID}"
        SP_JSON=`az ad sp create-for-rbac --role="${ROLE}" --scopes="/subscriptions/${AZURE_SUBSCRIPTION_ID}" -o tsv`
        export AZURE_CLIENT_ID=`printf %s "$SP_JSON" | cut -f1`
        export AZURE_CLIENT_NAME=`printf %s "$SP_JSON" | cut -f3`
        export AZURE_CLIENT_SECRET=`printf %s "$SP_JSON" | cut -f4`
        export AZURE_TENANT_ID=`printf %s "$SP_JSON" | cut -f5`
        echo "Now you can export these as environment variables:"
        echo "export AZURE_CLIENT_ID=${AZURE_CLIENT_ID}"
        echo "export AZURE_CLIENT_NAME=${AZURE_CLIENT_NAME}"
        echo "export AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}"
        echo "export AZURE_TENANT_ID=${AZURE_TENANT_ID}"
else
    echo "Your subscription couldn't be found, make sure you have logged in."
    exit 1
fi
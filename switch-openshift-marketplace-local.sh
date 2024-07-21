#!/bin/sh
source ./env-local.sh

CURRENT=$(KUBECONFIG=$MYDIR/auth/kubeconfig oc get OperatorHub cluster -o json | jq -r .spec.disableAllDefaultSources)

echo "currently: disableAllDefaultSources is set to $CURRENT"
if [ "$CURRENT" == "true" ]; then
    NEW="false"
elif [ "$CURRENT" == "false" ]; then
    NEW="true"
else
    echo "Something is not right, exciting"
    exit
fi


echo "Going to set it to: $NEW"



KUBECONFIG=$MYDIR/auth/kubeconfig oc patch OperatorHub cluster --type json -p "[{\"op\": \"add\", \"path\": \"/spec/disableAllDefaultSources\", \"value\": $NEW}]"

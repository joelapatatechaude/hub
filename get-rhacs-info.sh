#!/bin/sh
source ./env.sh

RHACS_SERVER=$(KUBECONFIG=$MYDIR/auth/kubeconfig oc get route central -n stackrox -o jsonpath='{.spec.host}')
echo "rhacs url : https://${RHACS_SERVER}"

RHACS_PASSWORD=$(KUBECONFIG=$MYDIR/auth/kubeconfig oc get secret central-htpasswd -n stackrox -o json | jq -r '.data."password"' | base64 -d)
echo "rhacs pwd : $RHACS_PASSWORD"

#!/bin/sh
source ./env.sh

ACS_SERVER=$(KUBECONFIG=$MYDIR/auth/kubeconfig oc get route central -n stackrox -o jsonpath='{.spec.host}')
echo "acs url : https://${ACS_SERVER}"
echo "acs ep  : $ACS_SERVER"

ACS_PASSWORD=$(KUBECONFIG=$MYDIR/auth/kubeconfig oc get secret central-htpasswd -n stackrox -o json | jq -r '.data."password"' | base64 -d)
echo "acs user: admin"
echo "acs pwd : $ACS_PASSWORD"

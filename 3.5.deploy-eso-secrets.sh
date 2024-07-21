#!/bin/sh
source ./env-local.sh
source ~/.secrets/akeyless-ocp-hub.txt

### THE API AKEYLESS CREDS
## THIS SECRET WILL BE REFERENCED BY THE clustersecretstore to be created later
KUBECONFIG=$MYDIR/auth/kubeconfig oc create -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: akeyless-secret-creds
  namespace: external-secrets
type: Opaque
stringData:
  accessId: $AKEYLESS_ACCESS_ID
  accessType:  api_key
  accessTypeParam:  $AKEYLESS_ACCESS_KEY
EOF

echo "done creating 1 secret for the ESO to access akeyless"

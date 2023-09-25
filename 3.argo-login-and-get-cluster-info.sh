#!/bin/sh
source ./env.sh
source <(curl -s https://raw.githubusercontent.com/joelapatatechaude/common-scripts/main/OCP-Demo/functions-get-cluster-info.sh)
#function trust_gitops {
#    #B=$(oc get configmap/openshift-service-ca.crt -n openshift-gitops -o jsonpath='{.data.service-ca\.crt}')
#    B=$(oc get configmap/openshift-gitops-ca -n openshift-gitops -o jsonpath='{.data.tls\.crt}')
#    echo $B
#    echo "$B" | sudo tee /etc/pki/ca-trust/source/anchors/$(uuidgen)-$CLUSTER_NAME-gitops-ca.crt > /dev/null
#    sudo update-ca-trust
#}


function patch_label {
    KUBECONFIG=$MYDIR/auth/kubeconfig oc patch argocds openshift-gitops -n openshift-gitops --type='merge' -p '{"spec":{"applicationInstanceLabelKey":"argocd.argoproj.io/instance"}}'
}

function patch_sub_health {
    KUBECONFIG=$MYDIR/auth/kubeconfig oc patch argocds openshift-gitops -n openshift-gitops --type='merge' --patch-file ArgoCD-patch_sub_health.yaml
}

function banner {
    cat <<EOF | KUBECONFIG=$MYDIR/auth/kubeconfig oc apply -f -
apiVersion: console.openshift.io/v1
kind: ConsoleNotification
metadata:
  name: gitops-banner
spec:
  backgroundColor: '#FF5F1F'
  color: '#000000'
  location: BannerTop
  text: Argo CD / ACM / ACS ($CLUSTER_NAME)
EOF
}

get_cluster_info

ARGO_SERVER=$(KUBECONFIG=$MYDIR/auth/kubeconfig oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
echo "argo url : https://${ARGO_SERVER}"
echo "argo ep  : $ARGO_SERVER"

ARGO_PASSWORD=$(KUBECONFIG=$MYDIR/auth/kubeconfig oc get secret openshift-gitops-cluster -n openshift-gitops -o json | jq -r '.data."admin.password"' | base64 -d)
echo "argo pwd : $ARGO_PASSWORD"

rm -f $ARGO_CONFIG
argocd login --username admin --password $ARGO_PASSWORD $ARGO_SERVER --config=$ARGO_CONFIG --insecure

KUBECONFIG=$MYDIR/auth/kubeconfig patch_label
KUBECONFIG=$MYDIR/auth/kubeconfig patch_sub_health
# KUBECONFIG=$MYDIR/auth/kubeconfig banner <- This is done in cluster-go/operators now.

#trust_gitops doesn't work as expected so far...
#KUBECONFIG=$MYDIR/auth/kubeconfig trust_gitops

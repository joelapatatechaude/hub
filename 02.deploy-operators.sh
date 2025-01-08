#!/bin/sh
source ./env.sh
echo "Looking ONLY for *.yaml files"

function apply {
    for i in `find operators -iname "*.yaml"`; do
	oc create -f $i;
    done
}


KUBECONFIG=$MYDIR/auth/kubeconfig apply

echo "Done, the operator may take a while to be ready"


#./3.argo-login-and-get-cluster-info.sh
#echo "next script (3.argo-login-and-get-cluster-info.sh got called"
#./get-cluster-info.sh
#./get-argo-info.sh

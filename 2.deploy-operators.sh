#!/bin/sh
source ./env.sh
echo "Looking ONLY for *.yaml files"



function post_apply {
    for i in `find post-operators -iname "*.yaml"`; do
	echo "-> post operators apply <-"
	oc apply -f $i;
    done
}

function pre_apply {
    for i in `find pre-operators -iname "*.yaml"`; do
	echo "-> pre operators apply <-"
	oc apply -f $i;
    done
}

function apply {
    for i in `find operators -iname "*.yaml"`; do
	echo "-> operators apply <-"
	oc apply -f $i;
    done
}

function wait {
    echo "Wait 5 seconds for subs to be applied"
    sleep 5
    LIST=$(oc get sub -A -o json | jq '.items[] | .metadata.name + " " + .metadata.namespace' -r)
    echo "List of operator / namespace to be ready:"
    echo "$LIST"
    while IFS= read -r i; do
	NAME=$(echo "$i" | awk '{print $1}')
	echo "Name is $NAME"
    	NS=$(echo "$i" | awk '{print $2}')
	echo "NS is $NS"
	while [ $(oc get sub ${NAME} -n $NS -o jsonpath='{.status.state}') != "AtLatestKnown" ]; do
	    echo "waiting for ${NAME} operator from $NS namespace to be ready..."
	    sleep 10
	done
	echo "=== $NAME seems ready ==="
    done <<< "$LIST"
}

#KUBECONFIG=$MYDIR/auth/kubeconfig oc new-project gitwebhook-operator
KUBECONFIG=$MYDIR/auth/kubeconfig pre_apply
sleep 1
KUBECONFIG=$MYDIR/auth/kubeconfig apply
KUBECONFIG=$MYDIR/auth/kubeconfig wait
KUBECONFIG=$MYDIR/auth/kubeconfig post_apply
# 10 seconds was tested and was not enough
SECONDS=60
echo "sleep $SECONDS before calling next script"
sleep $SECONDS
KUBECONFIG=$MYDIR/auth/kubeconfig post-apply
./3.argo-login-and-get-cluster-info.sh
echo "next script (3.argo-login-and-get-cluster-info.sh got called"
./get-cluster-info.sh
./get-argo-info.sh

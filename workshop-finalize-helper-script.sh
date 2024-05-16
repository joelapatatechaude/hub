#!/bin/sh

oc whoami
oc whoami --show-server


LIST=$(oc get project | grep '^exercise06-user' | awk '{print $1}');
echo "list of projets to finalize"
echo "$LIST"

echo ""

read -p "hit crtl-c to aboty, otherwise hit any key..."
echo "deleting in 2 seconds"
sleep 2

function cleanup() {
    R_TYPE=$1
    R_NAME=$2
    NAMESPACE=$3
    echo "deleteing $R_TYPE/$R_NAME in $NAMESPACE"
    oc patch $R_TYPE $R_NAME --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' -n $NAMESPACE

}

for i in $LIST
do
    echo "$i"
    cleanup "secret" "my-secret" $i
    cleanup "pod" "hello-world" $i
    cleanup "RoleBinding" "${i}-admin-wxyz" $i
    cleanup "Deployment" "tictactoe" $i
    cleanup "pod" "tictactoe" $i
    oc delete project $i --wait=false
done


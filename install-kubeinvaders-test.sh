#!/bin/sh

source ./env.sh

KUBEINVADERS_NS=kubeinvaders
KUBEINVADERS_TARGET_NS=chaos
KUBEINVADERS_INGRESS=kubeinvaders-kubeinvaders.apps.autotesting.sandbox994.opentlc.com
KUBEINVADERS_INGRESS=kubeinvaders-kubeinvaders.apps.gitops.sandbox994.opentlc.com
echo "Note that I am using a copy of the kubeinvader image from my quay repo, to avoid the risk of soft limit when pulling from docker.io"
echo "remember that the target namespace"
echo ""
echo "###############################################################"
echo "       ns: $KUBEINVADERS_NS"
echo "target ns: $KUBEINVADERS_TARGET_NS"
echo "  cluster: $OCP_HOSTNAME"
echo "  context: $CONTEXT"
echo "  ingress: $KUBEINVADERS_INGRESS"
echo "###############################################################"
echo ""
echo "if not happy hit ctrl-c now, otherwise hit any key"
read answer

#./oc login -u $OCP_ADMIN_USERNAME -p $OCP_ADMIN_PASSWORD $OCP_API_HOSTNAME:6443

helm repo add kubeinvaders https://lucky-sideburn.github.io/helm-charts/
helm repo update
./oc new-project $KUBEINVADERS_NS
echo "sleep 2"
sleep 2
#oc login -u $OCP_ADMIN_USERNAME -p $OCP_ADMIN_PASSWORD api.crc.testing:6443

helm install kubeinvaders \
     --set-string config.target_namespace="$KUBEINVADERS_TARGET_NS" \
     -n $KUBEINVADERS_NS \
     kubeinvaders/kubeinvaders \
     --set ingress.enabled=true \
     --set ingress.hostName=$KUBEINVADERS_INGRESS \
     --set deployment.image.tag=v1.9.6 \
     --kubeconfig=./cluster/auth/kubeconfig
#\
#     --set deployment.image.repository=quay.io/rh_ee_cschmitz/kubeinvaders

#oc login -u $OCP_ADMIN_USERNAME -p $OCP_ADMIN_PASSWORD $OCP_HOSTNAME:6443
#oc adm policy add-scc-to-user anyuid -z kubeinvaders
./oc project
./oc adm policy add-scc-to-user anyuid -z kubeinvaders
# oc expose service kubeinvaders AND update for edge termination, OR do below
# Importantly, the route need to be edge"
#oc login -u $OCP_USERNAME -p $OCP_PASSWORD $OCP_HOSTNAME:6443

./oc create route edge kubeinvaders --service=kubeinvaders -n $KUBEINVADERS_NS
#oc create route edge kubeinvaders --service=kubeinvaders -n $KUBEINVADERS_NS
echo ""
echo ""
echo "To remove jobs, run something like below (update the namespace to a single element, if it is a comma separated list) :"
echo "oc delete job -n "$KUBEINVADERS_TARGET_NS' `oc get job -n '$KUBEINVADERS_TARGET_NS" | grep chaos | awk ""'"'{print $1}'"'"' | xargs`'


echo "to delete all:"
echo "oc delete namespace $KUBEINVADERS_NS"

echo ""
echo "probably need to run the command: oc adm policy add-scc-to-user anyuid -z kubeinvaders"

#!/bin/sh
# NOTES: Attempt to simplify everything.
# NOTES: Wondering if I can change the domain name to go under cszevaco.

source ~/.aws/route53
source ~/.secrets/pullsecret
source ./env.sh


function cluster {
    date
    mkdir -p $MYDIR
    cp install-config.yaml.template ./$MYDIR/install-config.yaml
    sed -i "s/DOMAIN/$ROUTE53_DOMAIN/g" ./$MYDIR/install-config.yaml
    sed -i "s/REGION/$REGION/g" ./$MYDIR/install-config.yaml
    sed -i "s/CLUSTER_NAME/$CLUSTER_NAME/g" ./$MYDIR/install-config.yaml
    sed -i "s/PULL_SECRET/$PULL_SECRET/g" ./$MYDIR/install-config.yaml
    sed -i "s/MASTER_INSTANCE_TYPE/$MASTER_INSTANCE_TYPE/g" ./$MYDIR/install-config.yaml
    sed -i "s/WORKER_INSTANCE_TYPE/$WORKER_INSTANCE_TYPE/g" ./$MYDIR/install-config.yaml
    cd $MYDIR
    openshift-install create cluster
    cd ..
}

function trust {
    A=$(oc get configmap/kube-root-ca.crt -n openshift-service-ca -o jsonpath='{.data.ca\.crt}')
    echo "$A" | sudo tee /etc/pki/ca-trust/source/anchors/$(uuidgen)-$CLUSTER_NAME-OCPDEMO-ca.crt > /dev/null
    sudo update-ca-trust
    echo "done updating ca, you might need to restart your browser"
}


MYDIR=$MYDIR cluster
KUBECONFIG=$MYDIR/auth/kubeconfig trust
echo "done updating ca, you might need to restart your browser"

#!/bin/sh

source ./env.sh

function delete {
    date
    cd $MYDIR
    openshift-install destroy cluster
}

MYDIR=$MYDIR delete

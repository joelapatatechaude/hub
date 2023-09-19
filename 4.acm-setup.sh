#!/bin/bash


function private_repo_creds {
    cat <<EOF | KUBECONFIG=$GITOPS_KUBECONFIG oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: private-repo-creds
  namespace: openshift-gitops
  labels:
    argocd.argoproj.io/secret-type: repo-creds
stringData:
  type: git
  url: https://github.com/joelapatatechaude
EOF
}

function private_repo {
    REPO_URL=$(git remote get-url origin)
    REPO_NAME_FULL=$(echo $REPO_URL | awk -F '/' '{print $NF}')
    REPO_NAME=$(basename -s .git $REPO_NAME_FULL)
    cat <<EOF | KUBECONFIG=$GITOPS_KUBECONFIG oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: private-repo-$REPO_NAME
  namespace: openshift-gitops
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: $REPO_URL
  password: $GITHUB_PASSWORD
  username: $GITHUB_USERNAME
EOF
}

function github_pat_secret {
  # no issue here
  TOKEN=$(echo $GITHUB_WEBHOOK_PAC | base64 -w 0)
  cat <<EOF | KUBECONFIG=$GITOPS_KUBECONFIG oc apply -f -
kind: Secret
apiVersion: v1
metadata:
  namespace: gitwebhook-operator
  name: github-pat
data:
  token: $TOKEN
EOF
}

function gitwebhook_secret {
  # no issue here
  WEBHOOK_SECRET=$(echo $GITHUB_WEBHOOK_SECRET | base64 -w 0)
  cat <<EOF | KUBECONFIG=$GITOPS_KUBECONFIG oc apply -f -
kind: Secret
apiVersion: v1
metadata:
  namespace: gitwebhook-operator
  name: webhook-secret
data:
  secret: ${WEBHOOK_SECRET}
EOF
}

function gitwebhook {

  # while the CRD get crated correctly, it feels like the gitwebhook operator project has some bugs which
  # makes it's pod loopcrash with some null pointer exception.
  REPO_URL=$(git remote get-url origin)
  REPO_NAME_FULL=$(echo $REPO_URL | awk -F '/' '{print $NF}')
  REPO_NAME=$(basename -s .git $REPO_NAME_FULL)
  ARGO_SERVER=$(KUBECONFIG=$GITOPS_KUBECONFIG oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
  OWNER=joelapatatechaude

  echo $REPO_URL
  echo $REPO_NAME
  echo $GITHUB_WEBHOOK_PAC

cat <<EOF | KUBECONFIG=$GITOPS_KUBECONFIG oc apply -f -
apiVersion: redhatcop.redhat.io/v1alpha1
kind: GitWebhook
metadata:
  name: gitwebhook-github
  namespace: gitwebhook-operator
spec:
  gitHub:
    gitServerCredentials:
      name: github-pat
  repositoryOwner: $OWNER
  ownerType: user
  repositoryName: $REPO_NAME
  webhookURL: https://$ARGO_SERVER/api/webhook
  insecureSSL: false
  webhookSecret:
    name: webhook-secret
  events:
    - push
  contentType: json
  active: true
EOF
}

function manual_webhook {
  REPO_URL=$(git remote get-url origin)
  REPO_NAME_FULL=$(echo $REPO_URL | awk -F '/' '{print $NF}')
  REPO_NAME=$(basename -s .git $REPO_NAME_FULL)
  ARGO_SERVER=$(KUBECONFIG=$GITOPS_KUBECONFIG oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
  OWNER=joelapatatechaude

  echo $REPO_URL
  echo $REPO_NAME
  echo $GITHUB_WEBHOOK_PAC
  echo $ARGO_SERVER
  echo $OWNER

  #List existing hook on this repo
  LIST=$(curl -Ls \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_WEBHOOK_PAC"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$OWNER/$REPO_NAME/hooks)
  #echo $LIST
  ID_LIST=$(echo $LIST | jq .[].id -r)
  #echo "$ID_LIST"

  #delete existing hook
  for HOOK_ID in $(echo $ID_LIST); do
    curl -L \
    -X DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_WEBHOOK_PAC"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$OWNER/$REPO_NAME/hooks/$HOOK_ID
  done

  #create my new hook
  curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_WEBHOOK_PAC"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$OWNER/$REPO_NAME/hooks \
  -d "{\"name\":\"web\",\"active\":true,\"events\":[\"push\"],\"config\":{\"url\":\"https://$ARGO_SERVER/api/webhook\",\"content_type\":\"json\",\"insecure_ssl\":\"1\", \"secret\": \"$GITHUB_WEBHOOK_SECRET\"}}"

}


function create_argo_cluster {
    LIST=$(argocd cluster list --insecure --config $ARGO_CONFIG -o json | jq .[].name -r)
    echo "$LIST" | grep "${ARGO_CLUSTER_NAME}"
    if ! [ $? -eq 0 ]
    then
        echo "Adding the cluster $ARGO_CLUSTER_NAME to argocd"
        argocd cluster add $CONTEXT --config $ARGO_CONFIG --name $ARGO_CLUSTER_NAME -y --kubeconfig=$MYDIR/auth/kubeconfig --insecure
    fi
}

function create_app_project {
    echo "creating app project"
    cat <<EOF | oc apply -f -
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: $ARGO_CLUSTER_NAME
  namespace: openshift-gitops
spec:
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  destinations:
    - namespace: '*'
      server: '*'
  sourceRepos:
    - '*'
EOF
}

function deploy_app {
    for i in $(ls ${THEDIR:=cluster-go}/argo-app/*.yaml); do
	    oc apply -f $i
    done
}

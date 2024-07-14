ARGOCD in-cluster
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller


For DevSpaces: the github oauth is a sealed secret.
It looks like the sealed secret is sealed differently per cluster, so need to reseal the secret each time :(
The underlying github app has the devspaces endpoint encoded. Can I use multiple secrets for cloud / local? Does it even work with local?
https://github.com/settings/applications/new
application name: sandboxABCD
homepage URL: https://devspaces.apps.hub.sandboxABCD.opentlc.com/
Authorization callback URL: https://devspaces.apps.hub.sandboxABCD.opentlc.com/api/oauth/callback
Generate new client secret
Save the ID / Secret in the cluster-go/infrastructure/DevSpaces/github-oauth-secret.yaml
Reseal following the README, Make sure to pick the right local / non local.
But first, install the sealed infrastructure stuff.
Once sealed, remember to push


imagepuller: Now it's configured to be enabled via the che-cluster. But currently, it only pulls code and idea. Note udi-rhel8 by default.
Get the image via https://devspaces.apps.hub.cszevaco.com/plugin-registry/v3/external_images.txt and add rhel8-udi=lkdjf;ajfjd to the auto-created imagepuller CR.


gitconfig: I have to create a configmap, after the namespace has been created. It's awkard and not good


LOKI operator: stable5.8 hard coded in operator


hub project: currently public as I couldn't get the helm (workshop setup) to work in private repo.

ServiceMesh: I need to selectively apply servicemeshcontrolplane first before being able to apply the whole argocd thing.

GITLAB: Hard coded domain name (including hub) at this stage.

RHACS: I created a link inco for OpenShift console, the acs link is hardcoded
RHACS: need to manually create the bundle by clicking on the console on central, then apply the bundle with:
oc apply -n stackrox-secured -f ~/Downloads/hub-Operator-secrets-cluster-init-bundle.yaml


ODF:
This one consume sooo much CPU (14). At this stage, I am trying to lower the requests to ~100mi to all the deployments manually. Unclear if it sticks. I should write a job that does this automatically seriously.


cert manager operator:
remember I need to patch the certmanager cluster with:
spec:
  controllerConfig:
    overrideArgs:
      - '--dns01-recursive-nameservers=10.64.135.1:53,10.68.5.26:53'
      - '--dns01-recursive-nameservers-only=true'

Ideally, I need to write a job that also discover the nameservers first before patching the CM

Certificates:
hard coded commonName / dnsNames.





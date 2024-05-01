should probably remove the exercise05 string matching from main.go.

This admission controller will only hit namespaces with:
metadata:
  labels:
    musthavenodeselector: "true"

In the service,
  annotations:
    service.beta.openshift.io/serving-cert-secret-name: nsac-tls
auto-create a secret nsac-tls. This secret is then mounted (via deployment) into the pod. the main.go read the secrets (cert and key)

the ValidatingWebhookConfiguration auto-inject the ca-bundle (see annotations)
which means we don't need to specify the caBundle field

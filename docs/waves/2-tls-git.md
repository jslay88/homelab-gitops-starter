# Wave 2 — TLS and Git

## cert-manager

[cert-manager](https://cert-manager.io/docs/) (Jetstack chart, `crds.enabled: true`). Needed before ClusterIssuers (wave 4) and any Certificate. HTTP-01 and Ingress annotations: [docs](https://cert-manager.io/docs/usage/ingress/).

**Verify:** `kubectl get crd certificates.cert-manager.io`

## argocd-repo-creds

Required if you followed the recommendation and made the GitOps repo **private**. The kustomization starts **empty**. Seal a PAT (see [secrets](../secrets.md)) and add the SealedSecret to `values/argocd-repo-creds/kustomization.yaml` before this wave can pull.

Only delete `applications/argocd-repo-creds.yaml` if the copy is public (not recommended).

# Wave 2 — TLS and Git

## cert-manager

Jetstack chart, `crds.enabled: true`. Needed before ClusterIssuers (wave 4) and any Certificate.

**Verify:** `kubectl get crd certificates.cert-manager.io`

## argocd-repo-creds

Template only. The kustomization starts **empty**. If the GitOps repo is private, seal a PAT (see [secrets](../secrets.md)) and add the SealedSecret to `values/argocd-repo-creds/kustomization.yaml`.

If the repo is public, delete `applications/argocd-repo-creds.yaml`.

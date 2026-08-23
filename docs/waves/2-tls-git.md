# Wave 2 — TLS and Git

## cert-manager

[cert-manager](https://cert-manager.io/docs/) (Jetstack chart, `crds.enabled: true`). Needed before ClusterIssuers (wave 4) and any Certificate. HTTP-01 and Ingress annotations: [docs](https://cert-manager.io/docs/usage/ingress/).

**Verify:** `kubectl get crd certificates.cert-manager.io`

## argocd-repo-creds

Template only. The kustomization starts **empty**. If the GitOps repo is private, seal a PAT (see [secrets](../secrets.md)) and add the SealedSecret to `values/argocd-repo-creds/kustomization.yaml`.

If the repo is public, delete `applications/argocd-repo-creds.yaml`.

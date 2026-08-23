# Wave 2 — TLS and Git

## cert-manager

[cert-manager](https://cert-manager.io/docs/) (Jetstack chart, `crds.enabled: true`). Needed before ClusterIssuers (wave 4) and any Certificate. HTTP-01 and Ingress annotations: [docs](https://cert-manager.io/docs/usage/ingress/).

**Verify:** `kubectl get crd certificates.cert-manager.io`

## argocd-repo-creds

Required for a **private** GitOps repo. This Application does **not** unlock the first clone — Argo already needed a kubectl-created Secret to read `applications/` at all. See [bootstrap](../bootstrap.md#4-create-git-credentials-before-the-app-of-apps).

After wave 1, [seal that same PAT](../secrets.md) and add the SealedSecret to `values/argocd-repo-creds/kustomization.yaml`. Same Secret name (`repo-creds-github`) so Git takes over the object you created by hand.

Only delete `applications/argocd-repo-creds.yaml` if the copy is public (not recommended).

# Wave 2 — TLS and Git

## cert-manager

[cert-manager](https://cert-manager.io/docs/) (Jetstack chart, `crds.enabled: true`). Needed before ClusterIssuers (wave 4) and any Certificate. HTTP-01 and Ingress annotations: [docs](https://cert-manager.io/docs/usage/ingress/).

!!! success "Validation"
    Do not sync issuers (wave 4) until `kubectl get crd certificates.cert-manager.io clusterissuers.cert-manager.io` works and `kubectl -n cert-manager get pods` is Ready. A ClusterIssuer applied before these CRDs exists will sit as a bare unknown kind.

## argocd-repo-creds

Required for a **private** GitOps repo. This Application does **not** unlock the first clone — Argo already needed a kubectl-created Secret to read `applications/` at all. See [bootstrap](../bootstrap.md#4-create-git-credentials-before-the-app-of-apps).

After wave 1, [seal that same PAT](../secrets.md) and add the SealedSecret to `values/argocd-repo-creds/kustomization.yaml`. Same Secret name (`repo-creds-github`) so Git takes over the object you created by hand.

Only delete `applications/argocd-repo-creds.yaml` if the copy is public (not recommended).

!!! success "Validation"
    After you seal and sync: Argo UI → **Settings → Repositories** is still **Successful**, and `kubectl -n argocd get secret repo-creds-github --show-labels` still has `argocd.argoproj.io/secret-type=repo-creds`. Do not delete the kubectl-created Secret “to clean up” until Git has replaced it with the same name.

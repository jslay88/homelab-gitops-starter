Argo cannot clone a private repo until a `repo-creds` Secret exists. Create that Secret with kubectl **before** `kubectl apply -f master-application.yaml` — [bootstrap](../../docs/bootstrap.md#4-create-git-credentials-before-the-app-of-apps).

This Application only takes over that Secret in Git (SealedSecret) after wave 1. See `repo-creds.example.yaml` — do not commit an unsealed copy. After `kubeseal`, add the filename to `kustomization.yaml`. Same name as the bootstrap Secret.

Label: `argocd.argoproj.io/secret-type: repo-creds`.

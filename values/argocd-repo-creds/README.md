Seal a GitHub PAT (or leave this Application unused).

See `repo-creds.example.yaml` — do not commit an unsealed copy. After `kubeseal`, add the SealedSecret filename to `kustomization.yaml`.

Label the secret `argocd.argoproj.io/secret-type: repo-creds`.

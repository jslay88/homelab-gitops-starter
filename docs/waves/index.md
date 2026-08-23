# Waves

Each file in `applications/` is one Argo CD Application with `argocd.argoproj.io/sync-wave`.

| Wave | Applications | Optional? |
|------|----------------|-----------|
| 0 | `namespaces`, `metallb` | No |
| 1 | `sealed-secrets` | No if you will store secrets in Git |
| 2 | `cert-manager`, `argocd-repo-creds` | repo-creds: yes if the repo is public |
| 3 | `nginx-ingress` | No for this ingress model |
| 4 | `letsencrypt`, `step-issuer` | Yes — keep one issuer you will actually use |
| 5 | `longhorn`, `nfs-provisioner`, `csi-s3` | NFS and csi-s3: yes |
| 6 | `external-dns` | Yes if you create DNS records yourself |
| 7 | `argocd` | No (self-manage) |
| 8 | `metrics-server`, `cloudnative-pg` | CNPG: yes until you need Postgres |
| 9 | `plugin-barman-cloud`, `etcd-backup` | Yes |
| 10 | `kube-prometheus-stack` | Recommended; delete the file to skip |

**To skip:** delete (or move aside) the Application YAML and push. Do not leave a broken Application that cannot reach a `CHANGEME` endpoint if you never planned to fill it in.

Values that **must** change before a healthy sync are listed on each wave page.

# Waves

Each file in `applications/` is one Argo CD Application with `argocd.argoproj.io/sync-wave`. They are not one shape: some are a Helm chart, some are YAML in this repo, two are **both**. See [Application sources](../argo-sources.md).

| Wave | Applications | Optional? |
|------|----------------|-----------|
| 0 | `namespaces`, `metallb` | No |
| 1 | `sealed-secrets` | No if you will store secrets in Git |
| 2 | `cert-manager`, `argocd-repo-creds` | repo-creds: **required** for a private GitOps repo (recommended) |
| 3 | `nginx-ingress` | No for this ingress model |
| 4 | `letsencrypt`, `step-issuer` | Keep the issuer you will use. LAN names need [Step-CA](../step-ca.md), not LE. |
| 5 | `longhorn`, `nfs-provisioner`, `csi-s3` | NFS and csi-s3: yes |
| 6 | `external-dns` | Updates BIND only. Zone + LAN forward: [DNS](../dns.md). |
| 7 | `argocd` | No (self-manage) |
| 8 | `metrics-server`, `cloudnative-pg` | CNPG: yes until you need Postgres |
| 9 | `plugin-barman-cloud`, `etcd-backup` | Yes |
| 10 | `kube-prometheus-stack` | Recommended; delete the file to skip |

**To skip:** delete (or move aside) the Application YAML and push. Do not leave a broken Application that cannot reach a `CHANGEME` endpoint if you never planned to fill it in.

Values that **must** change before a healthy sync are listed on each wave page. Each wave has a **Validation** block: treat a failed check as a stop, not a “continue and see.”

Upstream manuals (MetalLB, cert-manager, Longhorn, F5 nginx, …) are linked from [versions](../versions.md). After the waves: [first app](../first-app.md), [Talos day-2](../talos-day2.md), [chart bumps](../upgrades.md).

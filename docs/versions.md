# Versions

Pins as of **August 2026**. Bump deliberately; do not float `latest`.

| Component | Pin | Source |
|-----------|-----|--------|
| Talos | v1.12.x (pick a patch at install time) | Image Factory |
| Kubernetes | whatever that Talos release ships | Talos release notes |
| Argo CD Helm chart | 8.6.0 | `argoproj.github.io/argo-helm` |
| MetalLB | 0.15.2 | `metallb.github.io/metallb` |
| sealed-secrets | 2.19.2 | `bitnami.github.io/sealed-secrets` |
| cert-manager | v1.21.1 | `charts.jetstack.io` |
| nginx-ingress (F5) | 2.6.4 | `ghcr.io/nginx/charts` |
| step-issuer | 1.11.0 | `smallstep.github.io/helm-charts` |
| Longhorn | 1.12.1 | `charts.longhorn.io` |
| nfs-subdir-external-provisioner | 4.0.18 | kubernetes-sigs Helm repo |
| csi-s3 | 0.43.7 | yandex-cloud Helm repo |
| external-dns image | v0.21.0 | `registry.k8s.io` |
| metrics-server | 3.14.0 | kubernetes-sigs Helm repo |
| cloudnative-pg | 0.29.0 | `cloudnative-pg.github.io/charts` |
| plugin-barman-cloud | 0.7.1 | same |
| kube-prometheus-stack | 88.5.0 | prometheus-community |

These match a long-lived homelab GitOps repo from the same period so the starter and that lab do not drift for no reason. When you bump, bump the Application `targetRevision` and this table together.

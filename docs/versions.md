# Versions

Pins as of **August 2026**. Bump deliberately; do not float `latest`. When you bump, bump the Application `targetRevision` and this table together. Procedure: [chart upgrades](upgrades.md). Talos/Kubernetes: [Talos day-2](talos-day2.md).

These match a long-lived homelab GitOps repo from the same period so the starter and that lab do not drift for no reason.

| Component | Pin | Docs | Chart / image |
|-----------|-----|------|----------------|
| [Talos](https://www.talos.dev/v1.12/) | v1.12.x (pick a patch at install) | [Getting started](https://www.talos.dev/v1.12/introduction/getting-started/), [VIP](https://www.talos.dev/v1.12/talos-guides/network/vip/), [etcd snapshot](https://www.talos.dev/v1.12/advanced/disaster-recovery/) | [Image Factory](https://factory.talos.dev/) |
| Kubernetes | whatever that Talos ships | [Kubernetes docs](https://kubernetes.io/docs/home/), [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/), [Service without selectors](https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors), [EndpointSlice](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/), [Pod Security](https://kubernetes.io/docs/concepts/security/pod-security-admission/) | Talos release notes |
| [Argo CD](https://argo-cd.readthedocs.io/en/stable/) | Helm 8.6.0 | [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/), [sync waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/) | `argoproj.github.io/argo-helm` |
| [MetalLB](https://metallb.io/) | 0.15.2 | [Layer 2](https://metallb.io/concepts/layer2/), [IPAddressPool](https://metallb.io/configuration/) | `metallb.github.io/metallb` |
| [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) | 2.19.2 | [Usage](https://github.com/bitnami-labs/sealed-secrets#usage) | `bitnami.github.io/sealed-secrets` |
| [cert-manager](https://cert-manager.io/docs/) | v1.21.1 | [HTTP-01](https://cert-manager.io/docs/configuration/acme/http01/), [Ingress annotations](https://cert-manager.io/docs/usage/ingress/#supported-annotations) | `charts.jetstack.io` |
| [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/) (F5) | 2.6.4 | [Annotations](https://docs.nginx.com/nginx-ingress-controller/configuration/ingress-resources/advanced-configuration-with-annotations/) | `ghcr.io/nginx/charts` |
| [Step-CA](https://smallstep.com/docs/step-ca/) | on the NAS | [Getting started](https://smallstep.com/docs/step-ca/getting-started/) | Unraid / host install |
| [step-issuer](https://github.com/smallstep/step-issuer) | 1.11.0 | [cert-manager integration](https://smallstep.com/docs/tutorials/kubernetes-cert-manager/) | `smallstep.github.io/helm-charts` |
| [Let's Encrypt](https://letsencrypt.org/docs/) | ACME HTTP-01 | [HTTP-01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge), [staging](https://letsencrypt.org/docs/staging-environment/) | ClusterIssuer in this repo |
| [Longhorn](https://longhorn.io/docs/1.12.1/) | 1.12.1 | [Architecture](https://longhorn.io/docs/1.12.1/concepts/), [Talos](https://longhorn.io/docs/1.12.1/advanced-resources/os-distro-specific/talos-linux-support/) | `charts.longhorn.io` |
| [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) | 4.0.18 | README (same repo) | kubernetes-sigs Helm repo |
| [csi-s3](https://github.com/yandex-cloud/k8s-csi-s3) | 0.43.7 | README (same repo) | yandex-cloud Helm repo |
| [MinIO](https://min.io/docs/minio/linux/index.html) | on the NAS | [S3 API](https://min.io/docs/minio/linux/integrations/aws-cli-with-minio.html) | Unraid / host install |
| [external-dns](https://kubernetes-sigs.github.io/external-dns/) | image v0.21.0 | [RFC2136](https://kubernetes-sigs.github.io/external-dns/latest/docs/tutorials/rfc2136/) | `registry.k8s.io` |
| [BIND 9](https://bind9.readthedocs.io/en/stable/) | on the NAS | [nsupdate / RFC2136](https://datatracker.ietf.org/doc/html/rfc2136) | Unraid / host install |
| [metrics-server](https://github.com/kubernetes-sigs/metrics-server) | 3.14.0 | README (same repo) | kubernetes-sigs Helm repo |
| [CloudNativePG](https://cloudnative-pg.io/documentation/current/) | chart 0.29.0 | [API / Cluster](https://cloudnative-pg.io/documentation/current/cloudnative-pg.v1/) | `cloudnative-pg.github.io/charts` |
| [Barman Cloud plugin](https://cloudnative-pg.io/plugin-barman-cloud/) | 0.7.1 | [Usage](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/) | same Helm repo |
| [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) | 88.5.0 | [Prometheus Operator](https://prometheus-operator.dev/docs/getting-started/introduction/), [Grafana](https://grafana.com/docs/grafana/latest/) | prometheus-community |
| [Flannel](https://github.com/flannel-io/flannel) (Talos default CNI) | Talos-shipped | README — **does not enforce NetworkPolicy** | Talos |

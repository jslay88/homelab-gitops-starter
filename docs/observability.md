# Observability

[`kube-prometheus-stack`](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) is wave **10** here so it does not block platform sync, but it is part of the starter. Operator docs: [Prometheus Operator](https://prometheus-operator.dev/docs/getting-started/introduction/). Grafana: [docs](https://grafana.com/docs/grafana/latest/). Delete `applications/kube-prometheus-stack.yaml` if you do not want it yet.

Namespace `monitoring` is privileged (wave 0) because exporters and node components need it.

The values file is minimal: default storage class (Longhorn), no Alertmanager receivers. Add Slack / Pushover / email yourself as SealedSecrets — do not copy someone else's pager config.

**Must change (optional):** Grafana admin via a sealed Secret ([below](#grafana-admin)), retention, PVC size.

!!! success "Validation"
    Before you add a Grafana Ingress:

    ```bash
    kubectl -n monitoring get pods   # prometheus, grafana, operator Ready
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
    # default user admin; password from Secret kube-prometheus-stack-grafana
    # After you seal grafana-admin, log in as that user instead — see below.
    ```

    Login on `:3000` must work. An Ingress on top of a CrashLoop Grafana will look like a cert problem. For the hostname path, [first app](first-app.md) must already have succeeded.

On one worker, Prometheus + Grafana + Longhorn plus platform pods will be tight on 8 GiB RAM. 16 GiB on the worker is more comfortable.

## What you get

- **Prometheus** — scrapes node-exporter, kube-state-metrics, and anything with a `ServiceMonitor` / `PodMonitor` in the cluster (chart defaults: `*SelectorNilUsesHelmValues` stay Helm-only unless you flip them). 7d retention, 20Gi Longhorn PVC in this repo.
- **Grafana** — dashboards the chart ships (Kubernetes / node). 5Gi PVC. **RWO:** set `grafana.deploymentStrategy.type: Recreate` if a RollingUpdate gets stuck with two pods on one volume (add that in your copy when you hit it).
- **Alertmanager** — enabled, **no routes**. Alerts fire into a black hole until you add receivers. That is intentional for v1.

This starter does not ship extra kubelet / kube-proxy scrape config. Talos + the chart’s defaults are enough to see nodes and pods. Custom `ServiceMonitor` objects belong next to the app that needs them.

## Grafana Ingress

When DNS + Step-CA work, add to `values/kube-prometheus-stack/values.yaml`:

```yaml
grafana:
  admin:
    existingSecret: grafana-admin
    userKey: admin-user
    passwordKey: admin-password
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      cert-manager.io/issuer: step-issuer
      cert-manager.io/issuer-kind: StepClusterIssuer
      cert-manager.io/issuer-group: certmanager.step.sm
      nginx.org/ssl-redirect: "true"
    hosts:
      - grafana.k8s.home.example.com
    tls:
      - secretName: grafana-tls
        hosts:
          - grafana.k8s.home.example.com
  persistence:
    enabled: true
    size: 5Gi
    storageClassName: longhorn
  deploymentStrategy:
    type: Recreate
```

Prove it like [first app](first-app.md): `dig` → Certificate Ready → browser with the root.

Do not put Grafana on a public Let's Encrypt name unless you mean the internet to see your cluster graphs.

## Grafana admin

Do not commit `grafana.adminPassword` in Helm values. The chart keeps reconciling that string, and a public fork would leak it.

Point Grafana at a Secret (the Ingress example above already does). Delete any leftover `adminPassword:` / `adminUser:` keys once the Secret exists.

```bash
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=labadmin \
  --from-literal=admin-password="$PASSWORD" \
  --dry-run=client -o yaml \
  | kubeseal --format=yaml --cert=pub-cert.pem \
  > values/kube-prometheus-stack/manifests/sealed-secret-grafana-admin.yaml
```

The kube-prometheus-stack Application is **chart + values** today. Add `path: values/kube-prometheus-stack/manifests` as a third source (same as [MetalLB](argo-sources.md)) and list the SealedSecret in that directory’s `kustomization.yaml`. Sync, then log in as `labadmin`.

Username is not secret; password is. Same sealing-key rules as [secrets](secrets.md). A leftover `admin` / `prom-operator` login means values still have `adminPassword` or the Secret was not mounted.

## Storage class

Prometheus and Grafana PVCs use `longhorn` (see [storage](waves/5-storage.md)). Do not move them to NFS.

# Observability

`kube-prometheus-stack` is wave **10** here so it does not block platform sync, but it is part of the starter. Delete `applications/kube-prometheus-stack.yaml` if you do not want it yet.

Namespace `monitoring` is privileged (wave 0) because exporters and node components need it.

The values file is minimal: default storage class (Longhorn), no Alertmanager receivers. Add Slack / Pushover / email yourself as SealedSecrets — do not copy someone else's pager config.

**Must change (optional):** Grafana admin password (or let the chart generate one and rotate), retention, PVC size.

**Verify:**

```bash
kubectl -n monitoring get pods
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

On one worker, Prometheus + Grafana + Longhorn plus platform pods will be tight on 8 GiB RAM. 16 GiB on the worker is more comfortable.

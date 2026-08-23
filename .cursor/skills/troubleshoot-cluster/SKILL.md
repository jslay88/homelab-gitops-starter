---
name: troubleshoot-cluster
description: >-
  Diagnoses this homelab GitOps cluster. Use when Applications are
  ComparisonError or OutOfSync, repo authentication required, EXTERNAL-IP
  pending, Certificate Issuing, ACME HTTP-01 fails, Ingress 502, dig empty,
  kubectl dies on CP reboot, Longhorn degraded, SealedSecret Error, or
  kubectl top is empty.
---

# Troubleshoot the cluster

Read `docs/troubleshooting.md` and walk **that** heading. Do not invent a fourth StorageClass, a second App-of-Apps, or `helm upgrade`.

## Order

1. Confirm kubeconfig: `export KUBECONFIG=~/talos/homelab/kubeconfig` and `kubectl get nodes`. If `server` is a node IP, stop — [API VIP](docs/talos-unraid.md).
2. `kubectl -n argocd get applications`. Unhealthy `platform` / empty children = clone failed. Wave 2 cannot fix the first clone.
3. Match the symptom to a heading in `docs/troubleshooting.md`. Run only those checks.
4. If a **Validation** block on the wave page fails, stop. Do not debug the next wave.
5. Change Git if the fix belongs in `applications/` or `values/`. Do not `kubectl apply` a chart that already has an Application.

## Read-only first

```bash
kubectl -n argocd get applications
kubectl get ingress,certificate,svc -A
kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp
```

`talosctl` uses `TALOSCONFIG=~/talos/homelab/_out/talosconfig` and endpoints `.11` `.12` `.13`, never `.20`.

## Do not

- Print Secret / PAT / TSIG / kubeconfig / `talosconfig` values.
- Create `kind: Endpoints` (use EndpointSlice).
- Use `cert-manager.io/cluster-issuer: step-issuer`.
- Skip `http01-edit-in-place` on public Ingresses.
- Point WAN 80/443 at a node or the API VIP.
- Recommend Longhorn replica 2 as the default (1 or 3).
- File an issue with live lab dumps. Docs bugs: `docs/help.md`.

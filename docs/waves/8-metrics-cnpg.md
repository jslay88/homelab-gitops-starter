# Wave 8 — Metrics and CNPG

## metrics-server

`--kubelet-insecure-tls` is enabled. Talos and kubeadm labs commonly need this for `kubectl top`.

**Verify:** `kubectl top nodes`

## cloudnative-pg

Operator only. No database Clusters. Add those in [day-2](../day-2.md) apps.

`ServerSideApply=true` for large CRDs.

**Skip:** delete `applications/cloudnative-pg.yaml` until you need Postgres.

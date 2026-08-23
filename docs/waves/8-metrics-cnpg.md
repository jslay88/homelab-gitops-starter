# Wave 8 — Metrics and CNPG

## metrics-server

[metrics-server](https://github.com/kubernetes-sigs/metrics-server). `--kubelet-insecure-tls` is enabled. Talos and kubeadm labs commonly need this for `kubectl top`.

**Verify:** `kubectl top nodes`

## cloudnative-pg

[CloudNativePG](https://cloudnative-pg.io/documentation/current/) operator only. No database Clusters. Add those in [day-2](../day-2.md) apps (including [Barman ObjectStore](../day-2.md#cnpg-backup-to-minio) after wave 9).

`ServerSideApply=true` for large CRDs.

**Skip:** delete `applications/cloudnative-pg.yaml` until you need Postgres.

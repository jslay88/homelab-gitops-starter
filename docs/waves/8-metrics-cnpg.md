# Wave 8 — Metrics and CNPG

## metrics-server

[metrics-server](https://github.com/kubernetes-sigs/metrics-server). `--kubelet-insecure-tls` is enabled. Talos and kubeadm labs commonly need this for `kubectl top`.

!!! success "Validation"
    `kubectl top nodes` prints CPU/memory for every node. Empty output: the Deployment is not Ready or `--kubelet-insecure-tls` was removed. Do not debug HPA until this works.

## cloudnative-pg

[CloudNativePG](https://cloudnative-pg.io/documentation/current/) operator only. No database Clusters. Add those in [day-2](../day-2.md) apps (including [Barman ObjectStore](../day-2.md#cnpg-backup-to-minio) after wave 9).

`ServerSideApply=true` for large CRDs.

**Skip:** delete `applications/cloudnative-pg.yaml` until you need Postgres.

!!! success "Validation"
    Before you add a `Cluster` in an app namespace:

    ```bash
    kubectl -n cnpg-system get deploy
    kubectl get crd clusters.postgresql.cnpg.io
    kubectl get sc longhorn   # default class must be Longhorn, not nfs
    ```

    Barman (`ObjectStore`) also needs [wave 9](9-backups.md) and a MinIO bucket. Do not create the database until Longhorn [validation](5-storage.md) passed.

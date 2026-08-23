# Wave 9 — Backups

Three different jobs. Do not mix them.

| What | Tool | Where bytes go |
|------|------|----------------|
| Kubernetes API objects | `talosctl etcd snapshot` | Workstation → NAS/S3 file |
| Longhorn volume contents | Longhorn backupstore | MinIO bucket |
| Postgres | Barman Cloud plugin + `ObjectStore` | MinIO prefix per database |

MinIO install: [Unraid extras](../unraid-extras.md). Seal keys: [secrets](../secrets.md#catalog). Skip this wave until the endpoint exists. The Applications are harmless idle if you never create an `ObjectStore` or a backup target.

## Longhorn → MinIO

[Set a backup target](https://longhorn.io/docs/1.12.1/snapshots-and-backups/backup-and-restore/set-backup-target/). Helm 1.12 uses `defaultBackupStore` (not only the old `defaultSettings.backupTarget`).

1. Bucket `longhorn-backups` on MinIO. Dedicated access key.
2. Seal Secret `longhorn-backup-s3` in namespace `longhorn`:

```yaml
# keys (stringData before you seal)
AWS_ACCESS_KEY_ID: CHANGEME
AWS_SECRET_ACCESS_KEY: CHANGEME
AWS_ENDPOINTS: http://10.0.0.2:9000
AWS_REGION: us-east-1
```

3. In `values/longhorn/values.yaml`:

```yaml
defaultBackupStore:
  backupTarget: s3://longhorn-backups@us-east-1/
  backupTargetCredentialSecret: longhorn-backup-s3
  pollInterval: "300"
```

The `@us-east-1` is the S3 region token Longhorn expects. MinIO ignores region as long as `AWS_ENDPOINTS` points at the API. Trailing slash on the URL matters; copy the docs form.

4. Sync. Longhorn UI → Backup: target should be Ready. Snapshot a test volume, Backup, then **Restore** to a new volume on a throwaway PVC before you trust it.

Workers must reach `10.0.0.2:9000`. This is not off-site unless MinIO is.

## plugin-barman-cloud

[Barman Cloud plugin](https://cloudnative-pg.io/plugin-barman-cloud/) ([usage](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/)). The Application only installs the plugin in `cnpg-system`. Each database needs its own `ObjectStore` + Secret + `ScheduledBackup` in the **app** namespace. Example: [day-2](../day-2.md#cnpg-backup-to-minio).

## etcd-backup

**Talos:** do not mount kubeadm hostPath certs. Use [`talosctl etcd snapshot`](https://www.talos.dev/v1.12/advanced/disaster-recovery/). The Application ships a **suspended** CronJob and a ConfigMap with the workstation command:

```bash
talosctl --nodes 10.0.0.11 etcd snapshot ./etcd-$(date -u +%Y%m%dT%H%M%SZ).snapshot
# then: copy to the NAS, or:
mc cp ./etcd-*.snapshot nas/etcd-snapshots/
```

Automate with a systemd timer on the workstation or a small always-on box that has `talosctl` + `TALOSCONFIG`. Do not unsuspend the in-cluster CronJob and expect it to speak the Talos API — that pod does not have your `talosconfig`.

Restore: [Talos day-2](../talos-day2.md#recover-etcd-from-a-snapshot). Snapshot ≠ Longhorn bytes.

**kubeadm / kubespray:** you would snapshot with `etcdctl` and host-mounted etcd certs. That path is cluster-specific and is **not** in this repo.

**Skip:** delete `applications/etcd-backup.yaml`.

# Wave 9 — Backups

## plugin-barman-cloud

CNPG plugin for backups to S3. Harmless without a Cluster. Needs an ObjectStore + credentials **per database** later (not in this starter).

## etcd-backup

**Talos:** do not mount kubeadm hostPath certs. The Application ships a **suspended** CronJob and a ConfigMap with the workstation command:

```bash
talosctl etcd snapshot ./etcd-$(date -u +%Y%m%dT%H%M%SZ).snapshot
```

Copy that file to the NAS or S3 yourself. Automate when you care.

**kubeadm / kubespray:** you would snapshot with `etcdctl` and host-mounted etcd certs. That path is cluster-specific and is **not** in this repo.

**Skip:** delete `applications/etcd-backup.yaml`.

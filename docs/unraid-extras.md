# MinIO and NFS on Unraid

BIND and Step-CA have their own pages. These two are the other NAS jobs the cluster may call. The starter does not install Unraid plugins. It expects an IP, a path, and credentials you seal.

Skip this whole page if you are Longhorn-only and do not want backups yet. Delete `applications/nfs-provisioner.yaml` and `applications/csi-s3.yaml`.

## NFS export (RWX)

Used by [nfs-subdir-external-provisioner](waves/5-storage.md). One directory on Unraid, many pods.

1. **Shares → Add share** (example name `k8s`). Prefer a **pool** (NVMe/SSD) if anything write-heavy will live here. `/mnt/user/k8s` works and is slower ([shfs](waves/5-storage.md#nfs--one-hop-to-the-nas-protocol--unraid-cost)).
2. **NFS:** export the share. Security: private. Rule that allows the **worker node** IPs (and CPs if you must), e.g. `10.0.0.21(rw,sec=sys,insecure)` and `.22` / `.23` as you add them. `insecure` is the usual Unraid need (source ports > 1024).
3. Map root: Unraid “NFS” UI **Maproot to `nobody`/`users`** (or a dedicated uid) so a pod running as root does not become root on the array. Pick one and stay consistent; uid-0 in the container vs uid-99 on disk is the classic “permission denied” after a remount.
4. From a Linux box on the LAN (not required on Talos):

```bash
showmount -e 10.0.0.2
# /mnt/user/k8s
```

5. `values/nfs-provisioner/values.yaml`: `nfs.server: 10.0.0.2`, `nfs.path: /mnt/user/k8s`.

!!! success "Validation"
    Do not sync `nfs-provisioner` until `showmount -e 10.0.0.2` lists the export and a Linux client (or a debug pod) can `mount` it read-write from a **worker** IP. “Share exists in the Unraid UI” is not the same as NFS allowing `.21`.

Each PVC becomes a **subdirectory** of that export (`nfs-subdir`). Deleting a PVC with `archiveOnDelete: true` renames the dir instead of rm. Clean those up by hand.

Unraid down = those PVCs unreadable. Do not put CNPG here.

## MinIO (S3 API)

Used as an **object** store: Longhorn backup target, CNPG Barman, `aws s3 cp` of etcd snapshots. Not a disk. See [storage](waves/5-storage.md#s3--cheap-to-keep-expensive-to-pretend-it-is-a-disk).

1. Official image `minio/minio` or the Unraid app. Persist the data dir on a share (`/mnt/user/minio` or a pool).
2. Console and API ports are yours. This guide’s examples use **API `9000`** on `http://10.0.0.2:9000`. If you terminate TLS on Unraid, use `https://` in every cluster Secret and trust that cert from the cluster (or stay on HTTP on the LAN).
3. First boot: set `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`. Those are **not** what you paste into Git. Create a **dedicated IAM user** (or access key) per job: `longhorn-backup`, `cnpg-barman`, `csi-s3` if you insist.
4. Buckets (example):

| Bucket | Who writes |
|--------|------------|
| `longhorn-backups` | Longhorn |
| `cnpg-backups` | Barman (`s3://cnpg-backups/<app>`) |
| `etcd-snapshots` | You, from the workstation |

5. From the workstation:

```bash
mc alias set nas http://10.0.0.2:9000 ACCESSKEY SECRET
mc mb nas/longhorn-backups nas/cnpg-backups nas/etcd-snapshots
mc anonymous set none nas/longhorn-backups
```

Do not make the buckets public. The cluster reaches MinIO from **worker node IPs** (masquerade), same as NFS and BIND. Unraid firewall: allow `.21`–`.29` to `9000`.

!!! success "Validation"
    Do not add [wave 9](waves/9-backups.md) targets until:

    ```bash
    curl -sI http://10.0.0.2:9000/minio/health/live
    mc ls nas/longhorn-backups
    ```

    Both must work with the **dedicated** key you will seal, not only the root user in the MinIO console.

Seal keys per [secrets](secrets.md#catalog). Wire Longhorn / CNPG per [backups](waves/9-backups.md).

MinIO on the same Unraid as the VMs is **not** off-site. A second disk, another NAS, or Backblaze/Wasabi is a different failure domain. This page only gets you an S3 endpoint.

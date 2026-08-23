# Wave 5 — Storage

## longhorn

Requires Talos Image Factory extensions and `kubelet.extraMounts` from the [Talos](../talos-unraid.md) chapter.

**Must change:** `defaultSettings.defaultReplicaCount` in `values/longhorn/values.yaml`.

| Workers with disks | Replica count |
|--------------------|---------------|
| 1 | `1` |
| 2 | `2` (or 1 if you accept no extra copy) |
| 3+ | `3` |

`preUpgradeChecker.jobEnabled: false` avoids a common first-sync failure.

**Verify:** `kubectl -n longhorn get pods` and the Longhorn UI (port-forward or later Ingress).

Backup target (MinIO) is optional. When you have S3 credentials, seal them and point Longhorn at the endpoint — not in this repo by default.

## nfs-provisioner (optional)

**Must change:** `nfs.server` and `nfs.path` in `values/nfs-provisioner/values.yaml`.

StorageClass name: `nfs` (not default). Delete the Application if you do not have an export.

## csi-s3 (optional)

S3-backed PVCs (this lab uses it for etcd snapshots in some kubeadm setups). Needs a SealedSecret the chart does not create (`secret.create: false`).

Delete the Application until MinIO exists.

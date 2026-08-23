# Wave 5 — Storage

Three provisioners, three jobs. Do not pick by “what mounts.” Pick by **how the bytes move**.

| | Longhorn | NFS (Unraid export) | S3 / MinIO |
|--|----------|---------------------|------------|
| What it is | Replicated **block** on worker disks | One NAS share over the LAN | Object store (HTTP) |
| Default access | RWO | RWX | Not a filesystem (unless you FUSE it) |
| Copies of the data | `replicaCount` full copies (1–3) | One (plus whatever Unraid parity already is) | One object (+ optional bucket versioning) |
| Typical hop | Pod → iSCSI → local (or peer) vDisk | Pod → NFS → Unraid NIC → array/pool | App → HTTPS → MinIO → Unraid disk |
| Best at | Databases, random IO, lots of fsync | Media, large sequential files, many pods one PVC | Backups, snapshots, artifacts |
| Worst at | Capacity (3× disk), RWX | Postgres, SQLite, small-file storms | Anything POSIX (unless you enjoy pain) |

Default StorageClass in this starter is **Longhorn**. NFS and csi-s3 are optional Applications. Delete them if you do not have the export or MinIO yet.

## How to choose

**Databases (CNPG, anything with WAL / fsync), app disks, PVC you think of as “a disk”** → Longhorn.

**Several pods reading or writing the same tree (media, incoming downloads, a shared cache)** → NFS. Longhorn RWX exists (it fronts NFS itself) and is the slower of the two Longhorn modes; this guide uses a real NAS export instead.

**Longhorn backups, Barman, etcd snapshot files, “put this tarball somewhere durable”** → S3 API against MinIO. Talk HTTP to the bucket. Do **not** make a `csi-s3` PVC and run Postgres on it.

| Workload | StorageClass / API | Why |
|----------|-------------------|-----|
| CNPG `Cluster` | `longhorn` | WAL and random writes. NFS will stall under `fsync`. |
| App RWO PVC | `longhorn` | Default. Local-ish block. |
| Media / RWX | `nfs` | One copy, many writers, sequential IO. |
| Longhorn backup target | S3 endpoint | Built-in; not a PVC. |
| CNPG Barman | S3 endpoint | Wave 9 plugin. |
| etcd snapshot | File on the workstation → NAS or `aws s3 cp` | [Wave 9](9-backups.md). Not a CSI volume on Talos. |

## Longhorn — fastest IO, you pay in copies

Longhorn is **replicated block**, not a clustered filesystem. A volume with `replicas: 3` is three full copies, one per worker disk, kept in sync over the worker LAN. That is the point: a node can die and the volume stays attachable. It is also the tax: 40 GiB PVC ≈ 120 GiB raw.

That is why it wins on IO. The engine speaks iSCSI to a replica. When the pod lands on a node that already has a replica (data locality), you are close to “disk on this VM.” When it does not, you still do block IO over the worker network — usually still far cheaper than NFS to Unraid and a parity array.

Overheads you actually feel:

- **Replica count.** `1` = fastest and smallest, no second copy. `3` = HA and rebuild traffic when a worker returns. Match replicas to **workers with Longhorn disks**, not to control-plane count. CPs do not hold replicas.
- **Rebuilds.** Adding a node or replacing a disk copies the whole volume across the LAN. Do not do that during a game download on the same NIC.
- **Unraid VM disk.** The vDisk is already virtualized. Longhorn on top is still the right default for databases. A second VirtIO disk at `/var/lib/longhorn` keeps the OS disk from filling.
- **RWX.** Possible, slower. Use NFS for share-shaped data.

On one worker, `defaultReplicaCount` **must** be `1` or volumes stay degraded forever.

## NFS — one hop to the NAS, protocol + Unraid cost

Every read and write is a network round trip to Unraid (or whatever exports the share). Gigabit plus Unraid’s share layer is fine for video and backups. It is a bad disk for a database.

Overheads:

- **NFS itself.** Metadata-heavy workloads (millions of tiny files, `git status`, SQLite) amplify latency. Sequential 4K movie files do not.
- **`/mnt/user/...` on Unraid.** User shares go through Unraid’s merger (shfs). That is extra userspace on the NAS. A dedicated pool or disk path (`/mnt/cache/k8s`, `/mnt/disk1/k8s`) is faster if you can dedicate it. This starter’s example path is `/mnt/user/k8s` because that is what most Unraid people already have — know that you paid a tax.
- **Parity / array writes.** A write to the Unraid array is not “one SSD.” It is the array’s write path. Put the export on a pool if the PVC is write-heavy.
- **Single head.** The NAS is the filesystem. Workers do not hold copies. Unraid down = those PVCs unreadable.
- **RWX is the reason it exists** in this repo. Longhorn already covers RWO.

Do not point CNPG at `storageClass: nfs`.

## S3 — cheap to keep, expensive to pretend it is a disk

MinIO (or any S3) is an **HTTP object** API. Listing, GET, PUT. That is the right shape for Barman WAL archives, Longhorn backupstores, and tarballs.

**csi-s3** mounts a bucket as a PVC through **FUSE** (GeeseFS / similar). Every `read()` becomes HTTP. Latency is terrible, POSIX locking is fiction, and databases will corrupt or crawl. This starter ships the Application because some labs used it for “a place to drop etcd snapshots” on kubeadm. On Talos, prefer `talosctl etcd snapshot` and copy the file to the bucket with the S3 API.

Overheads:

- Extra hop: pod → FUSE → HTTP → MinIO → Unraid disk.
- No useful `fsync`.
- MinIO on the same NAS as NFS: you did not get a second failure domain, only a second protocol.

Use S3 as S3. Skip `applications/csi-s3.yaml` until you have a concrete object that cannot use the AWS CLI or an operator’s built-in backup.

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

S3-backed PVCs via FUSE. Needs a SealedSecret the chart does not create (`secret.create: false`).

Delete the Application until MinIO exists, and even then prefer the S3 API over a PVC.

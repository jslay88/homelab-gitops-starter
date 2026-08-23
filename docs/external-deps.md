# External dependencies

These sit **outside** the cluster. The starter documents them; it does not install Unraid plugins.

| Need | Why the stack wants it | Unraid-shaped default | Substitute / skip |
|------|------------------------|----------------------|-------------------|
| Kubernetes API VIP | One kubeconfig URL that survives a CP reboot | Unused LAN IP (example `.20`), same L2 as the CPs | Talos `machine.network.interfaces[].vip`. **Do this** if you have 3 CPs. Not MetalLB. |
| L2 LB range | LoadBalancer Services (ingress, later apps) | Unused IPs on the same L2 as the nodes (example ingress `.30`, apps `.50–.99`) | MetalLB L2. **Do not skip** if you want this ingress model. Do not put `.20` in a pool. |
| Internal CA | Names that are not on the public internet (`*.k8s.home.example.com`) | [Step-CA](step-ca.md) on Unraid `:9005` | Let's Encrypt only, or mkcert. **Skip** if every name is public. |
| Public ACME | Browser-trusted certs for names the world can resolve | Let's Encrypt HTTP-01 through nginx | **Skip** if the lab is internal-only. WAN **80/443** must forward to the **ingress VIP**, not a node or the API VIP. |
| Authoritative DNS | external-dns creates A/TXT in **one** zone | [BIND](dns.md) on Unraid `:53` + TSIG (RFC2136) | Cloudflare / Route53, or a wildcard A on the router. |
| LAN resolver | Laptops and Talos nodes must *find* that zone | Router / Unbound / Pi-hole **forwards** `k8s.home.example.com` to BIND | Or make BIND the DHCP DNS (single point of failure). |
| Block storage | Default PVC class | Extra vDisk on each worker, Longhorn | **Required** for the storage model this guide teaches. |
| RWX | Shared filesystems | NFS export — [how](unraid-extras.md#nfs-export-rwx) | **Skip** and use Longhorn only. |
| Object storage | Longhorn backups, etcd snapshots, CNPG Barman | MinIO — [how](unraid-extras.md#minio-s3-api) | Any S3 API. **Skip** until you want backups. |
| Git | Source of truth | **Private** template copy of this repo + PAT | Public copy can skip repo-creds. **Do not.** |
| etcd snapshots | Cluster disaster recovery | `talosctl etcd snapshot` from a workstation | **Skip** in v1 if you accept rebuild-from-Git. Do **not** copy a kubeadm hostPath CronJob onto Talos. |

## Decision trees

**Internal TLS** — full procedure: [Step-CA](step-ca.md).

- All hostnames are public and HTTP-01 works → delete `applications/step-issuer.yaml`.
- You have `*.k8s.home.example.com` only on LAN → Step-CA on the NAS, then step-issuer. `cluster-issuer: step-issuer` is the wrong annotation.

**DNS** — full procedure: [local DNS](dns.md).

- Wildcard A on the router → delete `applications/external-dns.yaml`.
- BIND + TSIG → one zone, one SealedSecret, plus a **forward** from the LAN resolver.
- Cloudflare only → no internal zone; skip BIND and usually skip Step-CA.

**Storage extras** — IO vs copies vs protocol: [wave 5](waves/5-storage.md).

- One worker, no NAS share → Longhorn `defaultReplicaCount: 1`, delete nfs-provisioner and csi-s3.
- Three workers + Unraid → Longhorn 3 for disks/DBs, NFS for RWX media, MinIO as an **S3 API** for backups (not a csi-s3 PVC for Postgres).

## What this guide will not configure for you

OPNsense, Pi-hole, Cloudflare Workers, Pushover, and SSH-syncing certs onto a NAS UI. Those are lab-specific conveniences, not platform.

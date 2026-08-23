# External dependencies

These sit **outside** the cluster. The starter documents them; it does not install Unraid plugins.

| Need | Why the stack wants it | Unraid-shaped default | Substitute / skip |
|------|------------------------|----------------------|-------------------|
| L2 VIP range | LoadBalancer Services (ingress, later apps) | Unused IPs on the same L2 as the nodes | kube-vip or Cilium L2 later. **Do not skip** if you want this ingress model. |
| Internal CA | Names that are not on the public internet (`*.k8s.home.example.com`) | [Step-CA](https://smallstep.com/docs/step-ca/) on Unraid | Let's Encrypt only, or cert-manager self-signed. **Skip** if every name is public. |
| Public ACME | Browser-trusted certs for names the world can resolve | Let's Encrypt HTTP-01 through nginx | **Skip** if the lab is internal-only. Needs port 80 from the internet. |
| Authoritative DNS | external-dns creates A/AAAA from Ingress/Service | BIND on Unraid `:53` + TSIG (RFC2136) | Cloudflare / Route53 provider, or create records by hand. |
| LAN resolver | Nodes and laptops resolve your zones | Router DNS, or later Pi-hole | **Skip** Pi-hole for v1. Point Talos `nameservers` at the router. |
| Block storage | Default PVC class | Extra vDisk on each worker, Longhorn | **Required** for the storage model this guide teaches. |
| RWX | Shared filesystems | NFS export `/mnt/user/k8s` | **Skip** and use Longhorn only. |
| Object storage | Longhorn backups, etcd snapshots, CNPG Barman | MinIO on Unraid | Any S3 API. **Skip** until you want backups. |
| Git | Source of truth | This repo (template) + PAT if private | Public repo can skip repo-creds. |
| etcd snapshots | Cluster disaster recovery | `talosctl etcd snapshot` from a workstation | **Skip** in v1 if you accept rebuild-from-Git. Do **not** copy a kubeadm hostPath CronJob onto Talos. |

## Decision trees

**Internal TLS**

- All hostnames are public and HTTP-01 works → delete `applications/step-issuer.yaml`.
- You have `*.home.example.com` only on LAN → run Step-CA on the NAS, fill `values/step-issuer/manifests/issuer.yaml`, seal the provisioner password.

**DNS automation**

- You will type records into the router → delete `applications/external-dns.yaml`.
- You run BIND (or Unbound with RFC2136) → one zone, one TSIG SealedSecret.
- You already live in Cloudflare → change the Deployment to `--provider=cloudflare` and seal an API token instead of TSIG.

**Storage extras**

- One worker, no NAS share → Longhorn `defaultReplicaCount: 1`, delete nfs-provisioner and csi-s3.
- Three workers + Unraid → Longhorn 3, keep NFS if you want RWX media, keep MinIO for backups.

## What this guide will not configure for you

OPNsense, Pi-hole, Cloudflare Workers, Pushover, and SSH-syncing certs onto a NAS UI. Those are lab-specific conveniences, not platform.

# Addressing and topology

Reserve **blocks**, not the next free DHCP lease. You will add workers and pinned LoadBalancer IPs. If the first worker is `.12` because the first control plane is `.11`, the spreadsheet is already a mess.

**Use three control-plane nodes.** That is the recommended topology in this guide, not a later luxury. One CP means any reboot, disk check, or Unraid VM migrate takes the API and etcd with it — you cannot `kubectl` or Argo-sync your way through maintenance. Three CPs give etcd quorum: you can shut one down and the cluster stays up. Two is worse than one (either member dying loses quorum). Skip two.

This guide’s examples use `10.0.0.0/24` and the cluster name `homelab` (Talos files under `~/talos/homelab`). Use your own prefix; keep the **grouping**.

## Example layout (`10.0.0.0/24`)

| Block | Range | Role |
|-------|--------|------|
| Infra | `.1` | Gateway / LAN resolver (router, Unbound, Pi-hole) |
| Infra | `.2` | Unraid (BIND, Step-CA, NFS, MinIO) |
| Control plane | `.11`–`.19` | Talos CP nodes. Start at `.11`. Room for three (or more) without touching workers. |
| Pinned VIP | `.20` | Ingress LoadBalancer (MetalLB pool `ingress`). Seam between CP and workers. |
| Workers | `.21`–`.29` | Talos workers. Start at `.21`. |
| Other pinned VIPs | `.31`–`.39` | Stable LBs you do not want recycled (optional) |
| Dynamic LBs | `.50`–`.99` | MetalLB pool `apps` |

Recommended day-one cluster: **three** control planes at `10.0.0.11`–`.13`, **one** worker at `10.0.0.21` (add `.22` / `.23` when you want Longhorn replicas), ingress at `10.0.0.20`. Leave `.14`–`.19` empty.

Do **not** put the ingress VIP inside the control-plane or worker blocks. A VIP is not a node. DHCP must not hand out any of these ranges.

```text
10.0.0.1      router
10.0.0.2      unraid
10.0.0.11     talos-cp-01
10.0.0.12     talos-cp-02
10.0.0.13     talos-cp-03
10.0.0.14     (reserved)
10.0.0.20     ingress VIP
10.0.0.21     talos-worker-01
10.0.0.22     (reserved)
10.0.0.50-99  MetalLB apps
```

We say **control plane** / **CP**, not “master.” VM names: `talos-cp-01`, `talos-worker-01`. Kubernetes still has a `node-role.kubernetes.io/control-plane` taint; that is the same idea.

If your LAN is already `10.3.0.0/24` plus a Kubernetes VLAN, keep that. The point is a **written** map with slack in each role, not these exact octets.

## Three control planes (recommended)

This is what you want if you ever reboot a CP VM, apply a Talos upgrade, or let Unraid move a disk. With one CP, that work **is** a cluster outage: no API, no etcd, no Argo, no `kubectl`. Apps on workers may keep running until something needs the API (new pods, cert renew, a crash). That is a bad time to discover you needed quorum.

| | 3 CP (do this) | 1 CP (only if RAM is gone) |
|--|----------------|----------------------------|
| Maintenance | Shut down or upgrade **one** CP. The other two keep etcd quorum. `kubectl` still works if your kubeconfig can reach a live member. | Any reboot of that VM is an API outage. Restore from snapshot if the disk is gone. |
| VMs / RAM | Three × ~4 GiB. Twelve gigabytes is the tax. | One × 4 GiB. |
| `talosctl bootstrap` | Once, on `.11`. Apply the same `controlplane.yaml` family to `.12` and `.13` (per-node network patches). | Once, on `.11`. |
| How you talk to the API | `talosctl config endpoint` with **all three** IPs. For `kubectl`, prefer a DNS name with three A records, or point `--server` at a CP you are not rebooting. | `https://10.0.0.11:6443` is fine. |
| etcd | Quorum of 3. One dead member is OK. Two dead → cluster unavailable. | One member. That VM **is** etcd. |
| Longhorn | Unrelated. Replicas live on **workers**. | Same. |

**Two** control-plane nodes is the awkward number: etcd quorum is `(n/2)+1`. Either member dying loses quorum, and you still paid for a second VM. Skip 2.

Unraid is still a single hypervisor. Three CP VMs do not survive the host dying. They **do** survive the thing you actually do often: reboot one guest for a Talos upgrade, a disk resize, or “I need to pin this VM to another core.”

Growing 1 → 3 later works (`talosctl` join extra CP machines) but you will do your first upgrades on a cluster that cannot stay up during those upgrades. Prefer three from day one. `.14`–`.19` stay empty.

## Workers

One worker is enough to learn GitOps. Longhorn `defaultReplicaCount` must be `1`. Two workers can do replica `2`. Three workers can do `3` (the usual Longhorn default).

Adding a worker is: new VM, same Image Factory disk, `worker.yaml` with a **new** address from `.21`–`.29`, `talosctl apply-config`. You do not re-bootstrap.

## MetalLB vs node IPs

MetalLB announces **extra** IPs on the same L2. They must not collide with nodes, DHCP, or Unraid.

- Pool `ingress`: a `/32` (`10.0.0.20/32`) so the ingress Service is pinned.
- Pool `apps`: a range (`10.0.0.50-10.0.0.99`) for everything else.

Reserve the node blocks in the router DHCP server (or static-only those leases).

# Addressing and topology

Reserve **blocks**, not the next free DHCP lease. You will add a second worker, maybe a second and third control-plane node, and a handful of pinned LoadBalancer IPs. If the first worker is `.12` because the first control plane is `.11`, the spreadsheet is already a mess.

This guide’s examples use `10.0.0.0/24` and the cluster name `homelab` (Talos files under `~/talos/homelab`). Use your own prefix; keep the **grouping**.

## Example layout (`10.0.0.0/24`)

| Block | Range | Role |
|-------|--------|------|
| Infra | `.1` | Gateway / LAN resolver (router, Unbound, Pi-hole) |
| Infra | `.2` | Unraid (BIND, Step-CA, NFS, MinIO) |
| Control plane | `.11`–`.19` | Talos CP nodes. Start at `.11`. Room for three (or more) without touching workers. |
| Workers | `.21`–`.29` | Talos workers. Start at `.21`. |
| Pinned VIP | `.30` | Ingress LoadBalancer (MetalLB pool `ingress`) |
| Pinned VIPs | `.31`–`.39` | Other stable LBs you do not want recycled (optional) |
| Dynamic LBs | `.50`–`.99` | MetalLB pool `apps` |

Day-one cluster in the examples: **one** control plane at `10.0.0.11`, **one** worker at `10.0.0.21`, ingress at `10.0.0.30`. The empty addresses in `.12`–`.19` and `.22`–`.29` are intentional.

Do **not** put the ingress VIP inside the control-plane block. A VIP is not a node. DHCP must not hand out any of these ranges.

```text
10.0.0.1      router
10.0.0.2      unraid
10.0.0.11     talos-cp-01      ← first (maybe only) control plane
10.0.0.12     (reserved)       ← talos-cp-02 if you grow
10.0.0.13     (reserved)       ← talos-cp-03
10.0.0.21     talos-worker-01
10.0.0.22     (reserved)
10.0.0.30     ingress VIP
10.0.0.50-99  MetalLB apps
```

We say **control plane** / **CP**, not “master.” VM names: `talos-cp-01`, `talos-worker-01`. Kubernetes still has a `node-role.kubernetes.io/control-plane` taint; that is the same idea.

If your LAN is already `10.3.0.0/24` plus a Kubernetes VLAN, keep that. The point is a **written** map with slack in each role, not these exact octets.

## One control plane vs three

| | 1 CP (this starter’s default) | 3 CP |
|--|-------------------------------|------|
| VMs / RAM | One small VM (4 GiB) | Three. etcd + API on each. |
| `talosctl bootstrap` | Once, on `.11` | Same, once, on the first CP. Then join the other two with `controlplane.yaml`. |
| API VIP | Can be the node IP (`https://10.0.0.11:6443`) | You want a **stable** address (keep using `.11` as the first member, or put a kube-vip / DNS name in front). Clients should not chase whichever CP is up. |
| etcd | One member. That VM dies → API and etcd are gone. Restore from snapshot + Git. | Quorum of 3. One CP can reboot; the cluster stays up. Two dead → etcd unavailable. |
| Unraid lab | Honest default. The hypervisor is already a single point of failure. | Worth it if you already run three workers and care about rolling CP upgrades / disk failure on one VM. |
| Longhorn | Unrelated. Longhorn lives on **workers**. Extra CP nodes do not give you storage replicas. | Same. |

**Two** control-plane nodes is the awkward number: etcd quorum is `(n/2)+1`. Two members means either of them dying loses quorum. Skip 2. Use 1 or 3.

Growing 1 → 3 later is a supported Talos operation (`talosctl` join additional CP machines). It is easier if `.12` and `.13` were never given to a worker or a printer.

## Workers

One worker is enough to learn GitOps. Longhorn `defaultReplicaCount` must be `1`. Two workers can do replica `2`. Three workers can do `3` (the usual Longhorn default).

Adding a worker is: new VM, same Image Factory disk, `worker.yaml` with a **new** address from `.21`–`.29`, `talosctl apply-config`. You do not re-bootstrap.

## MetalLB vs node IPs

MetalLB announces **extra** IPs on the same L2. They must not collide with nodes, DHCP, or Unraid.

- Pool `ingress`: a `/32` (`10.0.0.30/32`) so the ingress Service is pinned.
- Pool `apps`: a range (`10.0.0.50-10.0.0.99`) for everything else.

Reserve the node blocks in the router DHCP server (or static-only those leases).

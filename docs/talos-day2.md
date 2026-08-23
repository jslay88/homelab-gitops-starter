# Talos day-2 (upgrade, grow, recover)

Three control planes and an [API VIP](talos-unraid.md#kubernetes-api-vip) exist so this chapter is boring. Do **one** guest at a time. Wait until `kubectl get nodes` and `talosctl health` are happy before the next.

Official: [upgrading Talos](https://www.talos.dev/v1.12/talos-guides/upgrading-talos/), [upgrading Kubernetes](https://www.talos.dev/v1.12/talos-guides/upgrading-kubernetes/), [disaster recovery](https://www.talos.dev/v1.12/advanced/disaster-recovery/).

```bash
export TALOSCONFIG=~/talos/homelab/_out/talosconfig
export KUBECONFIG=~/talos/homelab/kubeconfig
```

`talosctl` endpoints stay `.11` `.12` `.13`. Never the VIP.

!!! success "Validation"
    Do not upgrade, add a node, or restore until this is green. A second change on an already-degraded etcd is how you get a second outage.

```bash
talosctl health
kubectl get nodes -o wide
talosctl etcd members
talosctl --nodes 10.0.0.11,10.0.0.12,10.0.0.13 get addresses | grep 10.0.0.20
```

Take an etcd snapshot **before** an upgrade or a grow:

```bash
talosctl --nodes 10.0.0.11 etcd snapshot ./etcd-$(date -u +%Y%m%dT%H%M%SZ).snapshot
# copy that file off the workstation (NAS share or S3)
```

## Upgrade Talos (one node)

Use the **same Image Factory schematic** you installed with, new Talos tag. Changing extensions is a new schematic; do not mix installer IDs casually.

```bash
# pick a CP that is NOT the only one you can reach if something goes wrong
talosctl --nodes 10.0.0.13 upgrade \
  --image factory.talos.dev/installer/<SCHEMATIC_ID>:v1.12.y

# wait until that node is Ready and etcd has 3 members again
talosctl --nodes 10.0.0.13 service etcd
kubectl get node talos-cp-03
```

Then `.12`, then `.11`. Then workers, one at a time.

If Longhorn has `replicas: 1` and that replica lives on the worker you are rebooting, the volume goes offline. Drain first only if you have **another** replica (`replicas: 2+`) or you accept the outage:

```bash
kubectl drain talos-worker-01 --ignore-daemonsets --delete-emptydir-data
# upgrade / reboot
kubectl uncordon talos-worker-01
```

CPs are tainted. You do not drain them for workloads. You **do** wait for etcd.

## Upgrade Kubernetes

Talos ships a Kubernetes version. After every CP is on the new Talos, bump the API:

```bash
talosctl upgrade-k8s --to 1.35.x
```

`--to` must be a version **that Talos release supports**. Read the Talos release notes. Do not jump two minors in one sitting on a lab you care about.

## Add a worker

1. New VM (Unraid or [Proxmox](talos-proxmox.md)), same ISO / schematic as the others. Name `talos-worker-02`. Address from the worker block (`10.0.0.22`).
2. `patches/worker-02.yaml` — copy `worker-01`, change the address only. **No** `vip`.
3. Patch and apply:

```bash
talosctl machineconfig patch _out/worker.yaml --patch @patches/worker-02.yaml -o _out/worker-02.yaml
talosctl apply-config --insecure --nodes 10.0.0.22 --file _out/worker-02.yaml
```

After it is Ready, raise Longhorn `defaultReplicaCount` if you now have enough disks (see [storage](waves/5-storage.md)). Existing volumes do not magically grow replicas; set replica count on the volume or StorageClass going forward.

You do **not** re-bootstrap. You do **not** run `gen config` again (that would mint new certs). Keep `secrets.yaml`.

## Add a control plane (1 → 3, or 3 → 5)

Prefer three from day one. If you started at one:

1. Two new VMs, `.12` and `.13`, same schematic.
2. Same `secrets.yaml` / `_out/controlplane.yaml` you already have. Per-node network patches **with the same `vip.ip`**.
3. `apply-config` each new CP. They join etcd. Do not `bootstrap` again.
4. `talosctl config endpoint 10.0.0.11 10.0.0.12 10.0.0.13`
5. If kubeconfig still points at `.11` only, you generated against the wrong endpoint. Point `cluster.controlPlane.endpoint` at `https://10.0.0.20:6443` on **every** machine (new `gen config` against the VIP, or a `cluster.controlPlane.endpoint` patch) so kubelets and cert SANs include the VIP. Easier to have done VIP on day one.

etcd quorum is 3, 5, … — not 4. Skip even counts.

## Recover etcd from a snapshot

Only if quorum is gone (two of three CPs dead, or the single-CP lab died). If one CP is down, fix that member; do not restore.

1. Confirm you cannot recover quorum: `talosctl etcd members` / `talosctl service etcd` on whatever still boots.
2. Have the latest `*.snapshot` file.
3. Follow [Talos disaster recovery](https://www.talos.dev/v1.12/advanced/disaster-recovery/): wipe EPHEMERAL on broken members if needed, wait until etcd is `Preparing`, then:

```bash
talosctl --nodes 10.0.0.11 bootstrap --recover-from=./etcd-YYYYMMDD.snapshot
```

If the file was copied out of `/var/lib/etcd` with `talosctl cp` instead of `etcd snapshot`, add `--recover-skip-hash-check`.

Workers still have their disks. Longhorn data is not in etcd. etcd is API objects (what should exist). PVC **bytes** are on worker vDisks or in [S3 backups](waves/9-backups.md).

## Replace a dead VM

Same schematic, same machine config (or regenerate from `secrets.yaml` + the same patches). Same IP if you can; otherwise update DHCP, `talosctl config endpoint`, and any EndpointSlices that pointed at a node IP (you should not have those — EndpointSlices point at LAN apps, not nodes).

The hypervisor dying takes every guest. Three CPs do not survive that. Off-host copies of `secrets.yaml`, the sealing-key backup, etcd snapshots, and MinIO matter; see [secrets](secrets.md) and [backups](waves/9-backups.md).

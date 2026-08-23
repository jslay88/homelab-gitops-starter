# Talos on Unraid

Stand up a Kubernetes cluster as **Unraid VMs** running [Talos Linux](https://www.talos.dev/). Then [bootstrap Argo CD](bootstrap.md). Do not install Ubuntu “and then kubeadm” on these VMs.

**Recommended topology:** three control planes (`talos-cp-01`–`03` at `10.0.0.11`–`.13`) + at least one worker (`talos-worker-01` at `10.0.0.21`). We say **control plane / CP**, not master.

Three CPs are so you can reboot or upgrade **one** of them without losing etcd or `kubectl`. One CP makes every Talos upgrade an API outage. Two CPs is invalid for etcd quorum — skip two. Full rationale: [addressing](addressing.md).

Reserve `.11`–`.19` for CP and `.21`–`.29` for workers. Adding a worker later is another VM + `worker.yaml`, not a re-bootstrap.

On a **single worker**, Longhorn default replica count must be **1**. Three replicas need three schedulable disks.

## VM sizing

| Role | vCPU | RAM | Disks |
|------|------|-----|-------|
| Control plane (×3) | 2+ | 4 GiB each | 32–40 GiB OS |
| Worker | 4+ | 8 GiB | 40–80 GiB OS **plus** a second vDisk for Longhorn |

Longhorn should not share a tiny OS disk if you can avoid it. Attach a second VirtIO disk and mount it at `/var/lib/longhorn` (see patches below). If you only have one disk, it still works; space gets tight faster.

## Phase 0 — Workstation tools

```bash
curl -sL https://talos.dev/install | sh
# also: kubectl, helm, kubeseal (asdf, brew, or distro packages)
talosctl version --client
```

Keep `talosctl` on the same major/minor as the Talos image you boot.

## Phase 1 — Unraid VMs

In Unraid: **VMs → Add VM**. Suggested settings (same idea as [Talos on Proxmox](https://docs.siderolabs.com/talos/v1.12/platform-specific-installations/virtualized-platforms/proxmox)):

| Setting | Value |
|---------|--------|
| Machine | Q35 |
| BIOS | OVMF (UEFI) |
| SCSI / disk | VirtIO |
| NIC | VirtIO, bridged to LAN (the same L2 MetalLB will use) |
| ISO | Talos `metal-amd64` from [releases](https://github.com/siderolabs/talos/releases) **or** the Image Factory ISO from Phase 2 |
| Names | `talos-cp-01`, `talos-cp-02`, `talos-cp-03`, `talos-worker-01` |

Do not run the Unraid “install a distro” path. Power on, note the maintenance-mode IP (or plan static IPs in patches).

!!! note "Unraid vs Proxmox"
    The machine config is identical. Only the hypervisor UI changes. [Talos on Proxmox](talos-proxmox.md) is the same patches with a different host.

## Phase 2 — Image Factory (Longhorn extensions)

Longhorn on Talos needs extensions **baked into the installer**, not installed later.

1. Open [factory.talos.dev](https://factory.talos.dev/)
2. Pick your Talos version (see [versions](versions.md))
3. Add:
    - `siderolabs/iscsi-tools`
    - `siderolabs/util-linux-tools`
4. Save the schematic ID:

```text
factory.talos.dev/installer/<SCHEMATIC_ID>:v1.12.x
```

Use that as `--install-image`.

## Phase 3 — Generate configs

The YAML below is **patches**. Talos merges them into `_out/controlplane.yaml` and `_out/worker.yaml`.

```bash
export CLUSTER_NAME="homelab"
export CP1_IP="10.0.0.11"
export CP2_IP="10.0.0.12"
export CP3_IP="10.0.0.13"
export WORKER_IP="10.0.0.21"
export INSTALL_IMAGE="factory.talos.dev/installer/<SCHEMATIC_ID>:v1.12.x"
export GATEWAY="10.0.0.1"

mkdir -p ~/talos/${CLUSTER_NAME}/patches && cd ~/talos/${CLUSTER_NAME}
```

**`patches/common.yaml`** (both node types):

```yaml
machine:
  install:
    disk: /dev/vda
  kubelet:
    extraMounts:
      - destination: /var/lib/longhorn
        type: bind
        source: /var/lib/longhorn
        options:
          - bind
          - rshared
          - rw
  kernel:
    modules:
      - name: iscsi_tcp
      - name: nbd
```

If the worker has a **second** disk for Longhorn, add a user volume / mount for that disk in a worker-only patch after you see the device name (`talosctl get disks --insecure --nodes $WORKER_IP`). A single-disk lab can keep `/var/lib/longhorn` on the OS disk.

**One network patch per machine.** Same shape, different address. Do not share a single `controlplane-network.yaml` across three CPs.

| File | Address |
|------|---------|
| `patches/cp-01.yaml` | `10.0.0.11/24` |
| `patches/cp-02.yaml` | `10.0.0.12/24` |
| `patches/cp-03.yaml` | `10.0.0.13/24` |
| `patches/worker-01.yaml` | `10.0.0.21/24` |

Nameservers must be the **LAN resolver** (router / Pi-hole), the same one that [forwards `k8s.home.example.com` to BIND](dns.md). If you only set `8.8.8.8`, nodes and pods cannot resolve internal Ingress hosts.

```yaml
# patches/cp-01.yaml  (cp-02 / cp-03 / worker-01: change addresses only)
machine:
  network:
    interfaces:
      - interface: eth0
        addresses:
          - 10.0.0.11/24
        routes:
          - network: 0.0.0.0/0
            gateway: 10.0.0.1
    nameservers:
      - 10.0.0.1
```

A second worker is `patches/worker-02.yaml` with `10.0.0.22`, not an edit that steals `.14` from the CP block.

Confirm the NIC name:

```bash
talosctl get links --insecure --nodes ${CP1_IP}
talosctl get disks --insecure --nodes ${CP1_IP}
```

Generate:

```bash
talosctl gen secrets -o secrets.yaml

# Endpoint can be the first CP; kubeconfig/talosctl will list all three later.
talosctl gen config "${CLUSTER_NAME}" "https://${CP1_IP}:6443" \
  --with-secrets secrets.yaml \
  --output-dir _out \
  --install-image "${INSTALL_IMAGE}" \
  --config-patch @patches/common.yaml

talosctl machineconfig patch _out/controlplane.yaml --patch @patches/cp-01.yaml -o _out/cp-01.yaml
talosctl machineconfig patch _out/controlplane.yaml --patch @patches/cp-02.yaml -o _out/cp-02.yaml
talosctl machineconfig patch _out/controlplane.yaml --patch @patches/cp-03.yaml -o _out/cp-03.yaml
talosctl machineconfig patch _out/worker.yaml --patch @patches/worker-01.yaml -o _out/worker-01.yaml
```

Store `secrets.yaml` offline. It is how you recover `talosconfig`.

## Phase 4 — Install and bootstrap

VMs must be in maintenance mode (port 50000).

```bash
export TALOSCONFIG="$(pwd)/_out/talosconfig"

talosctl apply-config --insecure --nodes ${CP1_IP} --file _out/cp-01.yaml
talosctl apply-config --insecure --nodes ${CP2_IP} --file _out/cp-02.yaml
talosctl apply-config --insecure --nodes ${CP3_IP} --file _out/cp-03.yaml
talosctl apply-config --insecure --nodes ${WORKER_IP} --file _out/worker-01.yaml

# After the first CP is up, bootstrap etcd once — only on cp-01:
talosctl config endpoint ${CP1_IP} ${CP2_IP} ${CP3_IP}
talosctl config node ${CP1_IP}
talosctl bootstrap
talosctl kubeconfig .
kubectl --kubeconfig ./kubeconfig get nodes
```

`bootstrap` runs **once**. The other two CP VMs join etcd with the same cluster secrets.

Wait until four nodes are Ready (3 CP + 1 worker). If you reboot `talos-cp-01` later, `talosctl` still has `.12` and `.13` as endpoints. `kubectl` uses a single `--server` (the first CP from `gen config`); point it at another CP or a DNS name with three A records while `.11` is down.

Then go to [bootstrap](bootstrap.md).

## PSA reminder

Talos enforces Pod Security. Wave 0 labels `metallb-system`, `longhorn`, `nfs-provisioner`, `nginx-ingress`, and `monitoring` as `enforce=privileged`. If you skip that Application, MetalLB and Longhorn will not start.

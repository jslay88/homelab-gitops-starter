# Talos on Proxmox

Stand up the same Kubernetes cluster as [Talos on Unraid](talos-unraid.md), as **Proxmox VE** guests ([Talos Proxmox guide](https://www.talos.dev/v1.12/talos-guides/install/virtualized-platforms/proxmox/)). Then [bootstrap Argo CD](bootstrap.md). Do not install Debian “and then kubeadm” on these VMs.

The **machine config is identical**. This page is the hypervisor: ISO upload, Create VM, disks, bridge, firewall. Patches, `gen config`, `apply-config`, and the [API VIP](talos-unraid.md#kubernetes-api-vip) live on the Unraid page so the two paths cannot drift.

**Recommended topology:** three control planes (`talos-cp-01`–`03` at `10.0.0.11`–`.13`) + a Talos **API VIP** at `10.0.0.20` + at least one worker (`talos-worker-01` at `10.0.0.21`). We say **control plane / CP**, not master. Rationale: [addressing](addressing.md).

On a **single worker**, Longhorn `defaultReplicaCount` must be **1**. Three replicas need three schedulable disks.

BIND, Step-CA, NFS, and MinIO still sit **outside** the cluster. On a Proxmox-only lab that is another VM, an LXC, or a NAS — not a pod. [DNS](dns.md), [Step-CA](step-ca.md), [MinIO and NFS](unraid-extras.md).

## VM sizing

| Role | vCPU | RAM | Disks |
|------|------|-----|-------|
| Control plane (×3) | 2+ | 4 GiB each | 32–40 GiB OS |
| Worker | 4+ | 8 GiB | 40–80 GiB OS **plus** a second disk for Longhorn |

Three CPs on **one** PVE node still die if that host dies. They exist so you can reboot or upgrade **one guest**. If you have a Proxmox cluster, spreading CPs across nodes is nicer; it is not required for this guide.

## Phase 0 — Workstation tools

```bash
curl -sL https://talos.dev/install | sh
# also: kubectl, helm, kubeseal (asdf, brew, or distro packages)
talosctl version --client
```

Keep `talosctl` on the same major/minor as the ISO you boot.

!!! success "Validation"
    `talosctl version --client` matches the [pinned](versions.md) Talos minor. `kubectl` and `helm` are on `$PATH`. Do not generate machine configs with a client from a different major.

## Phase 1 — Proxmox VMs

Official settings: [Talos on Proxmox](https://www.talos.dev/v1.12/talos-guides/install/virtualized-platforms/proxmox/). Create **four** guests: `talos-cp-01`, `talos-cp-02`, `talos-cp-03`, `talos-worker-01`.

### Upload the ISO

1. Build or download a **metal** ISO from [Image Factory](https://factory.talos.dev/) (Phase 2 — do that first if you want Longhorn). Vanilla `metal-amd64` from [releases](https://github.com/siderolabs/talos/releases) is enough to reach maintenance mode; the **installer** image on `gen config` still needs the Longhorn schematic.
2. In Proxmox: storage **local** (or wherever you keep ISOs) → **ISO Images** → **Upload**.

Do not use a cloud image, a Proxmox “Turnkey” template, or cloud-init. Talos is the ISO → `apply-config` → installed-to-disk path.

### Create VM (wizard)

**Create VM** for each guest. Tabs that matter:

| Tab | Setting | Value |
|-----|---------|--------|
| General | Name | `talos-cp-01` … `talos-worker-01` |
| OS | ISO | the metal / Factory ISO |
| OS | Guest OS | Other / Linux 6.x is fine. Talos is not Debian. |
| System | Machine | **q35** |
| System | BIOS | **OVMF (UEFI)** |
| System | EFI Disk | yes (4 MiB). Uncheck **Pre-Enroll keys** (Secure Boot is a different path). |
| System | QEMU Agent | **off** unless the ISO includes `siderolabs/qemu-guest-agent` |
| System | TPM | not required for this guide |
| Disks | Bus | **VirtIO SCSI** — **not** “VirtIO SCSI Single” |
| Disks | Size | 32–40 GiB CP; 40–80 GiB worker OS |
| Disks | Cache | Write through (or None) |
| Disks | Discard / SSD | on if the datastore is SSD |
| CPU | Cores | 2+ CP, 4+ worker. Sockets **1**. |
| CPU | Type | **host** (best). `kvm64` only if you must live-migrate on old PVE. |
| Memory | Size | 4 GiB CP, 8 GiB worker |
| Memory | Ballooning | **off**. Talos does not do memory hotplug; ballooning lies about RAM. |
| Network | Model | VirtIO |
| Network | Bridge | the **LAN** bridge (`vmbr0` in the examples) |
| Network | VLAN | only if that tag is the same L2 MetalLB and the API VIP will use |

Add a **serial port** (`serial0` / ttyS0). Early boot and “no DHCP” are easier there than on the VGA console.

**Hard Disk controller:** VirtIO SCSI Single has hung Talos bootstrap and hidden disks ([talos#11173](https://github.com/siderolabs/talos/issues/11173)). If `talosctl get disks --insecure` is empty, this is the first thing to check.

### Worker: second disk

On `talos-worker-01` only: **Add → Hard Disk**, same VirtIO SCSI controller, 40+ GiB. That becomes `/dev/vdb` (confirm later). Longhorn should not share a tiny OS disk if you can avoid it. A one-disk lab still works; space gets tight faster.

### Do not

- Enable Proxmox **cloud-init** (no extra cloud-init drive).
- Clone a **running** Talos VM. IDs and disks are unique. Clone only a stopped, never-`apply-config`’d template.
- Turn on the **VM firewall** until you know DHCP, `50000/tcp`, and the LAN work. A default-deny guest firewall looks like “maintenance mode never gets an IP.”
- Put the guests on a NAT-only or isolated `vmbr` that is not the LAN. MetalLB L2 and the API VIP are ARP on that bridge.

Start the four VMs. Each boots the ISO into **maintenance mode** (Talos API on port 50000). The console prints the DHCP address. If you have no DHCP, interrupt the bootloader (`e`) and set a kernel `ip=` as in the [upstream guide](https://www.talos.dev/v1.12/talos-guides/install/virtualized-platforms/proxmox/) — then put the same address in the network patch so it survives install.

!!! success "Validation"
    Four guests exist and are in maintenance mode. From the workstation:

    ```bash
    talosctl get version --insecure --nodes 10.0.0.11
    # same for .12, .13, .21
    talosctl get disks --insecure --nodes 10.0.0.11
    talosctl get links --insecure --nodes 10.0.0.11
    ```

    Timeout → wrong bridge, VLAN, or firewall. Empty disks → VirtIO SCSI Single or the ISO has not actually booted. Do not `gen config` until port 50000 answers.

## Phase 2 — Image Factory (Longhorn + optional QEMU agent)

Longhorn on Talos needs extensions **baked into the installer**, not installed later.

1. Open [Image Factory](https://factory.talos.dev/)
2. Pick the [pinned](versions.md) Talos version
3. Add:
    - `siderolabs/iscsi-tools`
    - `siderolabs/util-linux-tools`
    - optionally `siderolabs/qemu-guest-agent` (Proxmox guest shutdown / IP in the UI)
4. Save the schematic ID. Use it for **both** the metal ISO (if you rebuild) and `--install-image`:

```text
factory.talos.dev/installer/<SCHEMATIC_ID>:v1.12.x
```

One schematic for every node. Mixing a vanilla ISO install with a Factory installer (or the other way around) is how workers come up without iSCSI.

If you added `qemu-guest-agent`, enable **QEMU Guest Agent** on each VM (Options). If you did not, leave it off — Proxmox will only log that the agent never answered.

!!! success "Validation"
    `INSTALL_IMAGE` is `factory.talos.dev/installer/<id>:v1.12.x`, not `ghcr.io/siderolabs/installer`. Longhorn will not start on a node that never got `iscsi-tools`.

## Phase 3–4 — Config, apply, bootstrap

Patches, `talosctl gen config` against **`https://10.0.0.20:6443`**, per-node network files, `apply-config`, and `bootstrap` are the same as [Unraid phases 3–4](talos-unraid.md#phase-3--generate-configs). Copy those files. Disk is usually `/dev/vda` — believe `talosctl get disks`, not habit.

```bash
export CLUSTER_NAME="homelab"
export CP1_IP="10.0.0.11"
export CP2_IP="10.0.0.12"
export CP3_IP="10.0.0.13"
export API_VIP="10.0.0.20"
export WORKER_IP="10.0.0.21"
export INSTALL_IMAGE="factory.talos.dev/installer/<SCHEMATIC_ID>:v1.12.x"
export TALOSCONFIG=~/talos/${CLUSTER_NAME}/_out/talosconfig

# after the Unraid-page generate + patch steps:
talosctl apply-config --insecure --nodes ${CP1_IP} --file _out/cp-01.yaml
talosctl apply-config --insecure --nodes ${CP2_IP} --file _out/cp-02.yaml
talosctl apply-config --insecure --nodes ${CP3_IP} --file _out/cp-03.yaml
talosctl apply-config --insecure --nodes ${WORKER_IP} --file _out/worker-01.yaml

talosctl config endpoint ${CP1_IP} ${CP2_IP} ${CP3_IP}
talosctl config node ${CP1_IP}
talosctl bootstrap
talosctl kubeconfig .
```

`bootstrap` runs **once**, on cp-01. `talosctl` endpoints are the **node** IPs, never the VIP. After install the guests reboot off disk; you can drop the ISO from the boot order (Options → Boot Order → `scsi0` first).

!!! success "Validation"
    Do not start [Argo bootstrap](bootstrap.md) until all of these pass:

    ```bash
    kubectl get nodes   # 4 Ready: 3 control-plane + 1 worker
    kubectl config view --minify | grep server   # https://10.0.0.20:6443
    ping -c 2 10.0.0.20
    curl -k https://10.0.0.20:6443/version
    talosctl etcd members   # 3 members
    ```

## Networking that bites on Proxmox

The API VIP and MetalLB are **Layer 2 ARP** on the same bridge as the guest NICs.

| Symptom | Check |
|---------|--------|
| No DHCP / no `50000` | VM firewall; datacenter firewall; guest not on `vmbr0` |
| `get disks` empty | VirtIO SCSI Single; ISO still the only “disk” |
| API VIP never appears | `vip.ip` missing on a CP; `gen config` used a node URL; etcd not bootstrapped |
| MetalLB `<pending>` | Speakers cannot ARP on this bridge (isolated VLAN, “firewall” on the tap) |
| Laptop cannot reach `.20` / `.30` | You used `vmbr1` (NAT) or a VLAN the workstation is not on |

If the Proxmox **host** firewall is on, allow at least: DHCP, `50000/tcp` from the workstation, `6443/tcp` from the workstation (to the VIP and the three CP IPs), and the LAN path workers use to BIND / Step-CA / MinIO. Guest firewall: start off; add rules later if you must.

## Snapshots are not etcd

A Proxmox snapshot of three CP VMs is not a consistent cluster backup. Snapshot one CP while etcd is writing and you can get a surprise on rollback. Use [`talosctl etcd snapshot`](talos-day2.md) and [wave 9](waves/9-backups.md). Keep `secrets.yaml` and the [sealing key](secrets.md#back-up-the-sealing-key) off the hypervisor.

Rolling back a **worker** snapshot can confuse Longhorn (replica UUID vs disk contents). Prefer Longhorn backups to MinIO.

`host` CPU type blocks live-migrate. That is fine. If you migrate anyway, expect a few seconds of VIP / MetalLB flap — same as rebooting that guest.

## Next

- [API VIP](talos-unraid.md#kubernetes-api-vip) — generate against `.20` from day one.
- [Bootstrap Argo CD](bootstrap.md)
- [Talos day-2](talos-day2.md) — upgrade, add a worker, restore etcd. Adding a worker is another Proxmox VM + `worker.yaml`, not a re-bootstrap.

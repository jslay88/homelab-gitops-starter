# Talos on Proxmox

Same cluster as [Talos on Unraid](talos-unraid.md). Only the VM host changes.

Create **four** VMs to start: `talos-cp-01`–`03` and `talos-worker-01`. Same [addressing](addressing.md) as Unraid: CP nodes in `.11`–`.19`, API VIP at `.20` (not a VM), workers in `.21`–`.29`. Three control planes plus the VIP so you can maintain one guest without losing `kubectl`.

[Talos Proxmox docs](https://docs.siderolabs.com/talos/v1.12/platform-specific-installations/virtualized-platforms/proxmox):

| Setting | Value |
|---------|--------|
| Machine | `q35` |
| BIOS | OVMF |
| SCSI | VirtIO SCSI |
| CPU / RAM | 2 vCPU / 4 GiB CP; 4 vCPU / 8 GiB worker |
| Disk | ≥ 32 GiB; extra disk on the worker for Longhorn |
| NIC | VirtIO on the LAN bridge (`vmbr0`) |
| ISO | Talos metal image or Image Factory ISO |

Then follow Unraid phases 2–4: Image Factory extensions, the same patches, `apply-config`, `bootstrap`, kubeconfig. Use the **Validation** blocks on that page the same way — four Ready nodes and `server: https://10.0.0.20:6443` before [bootstrap](bootstrap.md). Day-2 (upgrade, grow, recover) is the same: [Talos day-2](talos-day2.md).

VirtIO disks are usually `/dev/vda`. Check with `talosctl get disks --insecure`.

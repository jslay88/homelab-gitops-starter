# Fill-in inventory

Do this **before** editing YAML. Every `CHANGEME` in the repo maps to a row here. Read [addressing](addressing.md) before you pick node IPs — reserve a control-plane block and a worker block; do not number a worker as “CP + 1”.

| Item | Your value | Example | Used by |
|------|------------|---------|---------|
| GitHub repo URL | | `https://github.com/you/homelab-gitops-starter.git` | Every Application `repoURL` |
| Cluster name | | `homelab` | Talos `gen config` (`~/talos/homelab`) |
| LAN CIDR | | `10.0.0.0/24` | See [addressing](addressing.md) — reserve blocks, do not pack nodes |
| Gateway | | `10.0.0.1` | Talos default route, DNS upstream |
| Control plane block | | `10.0.0.11`–`.19` | Use `.11` `.12` `.13` on day one (recommended). Leave `.14`–`.19` empty. |
| Kubernetes API VIP | | `10.0.0.20` | Talos shared VIP. kubeconfig `https://10.0.0.20:6443`. Not a VM, not MetalLB. |
| Worker block | | `10.0.0.21`–`.29` | First worker is `.21`. Not `.12`. |
| MetalLB pool (apps) | | `10.0.0.50-10.0.0.99` | `values/metallb` |
| Ingress VIP | | `10.0.0.30` | MetalLB pool `ingress`. Not `.20`. |
| LAN resolver (DHCP DNS) | | `10.0.0.1` | Router / Pi-hole; must forward the cluster zone |
| DNS zone (internal) | | `k8s.home.example.com` | BIND + external-dns + Step-CA names |
| DNS zone (public, optional) | | `k8s.example.com` | Let's Encrypt hostnames |
| Argo webhook hostname (optional) | | `argocd.example.com` | Public `/api/webhook` only. [Wave 7](waves/7-argocd.md#github-webhook). |
| Argo / Grafana admin username | | `labadmin` | Values / Secret key. Password is sealed, not this table. |
| BIND / RFC2136 host | | `10.0.0.2` | Authoritative for the internal zone |
| TSIG key name | | `externaldns-key` | external-dns (seal the secret) |
| ACME email | | `you@example.com` | Let's Encrypt ClusterIssuer |
| Step-CA URL | | `https://10.0.0.2:9005` | step-issuer; skip only if no LAN names |
| NFS server + path (optional) | | `10.0.0.2:/mnt/user/k8s` | nfs-provisioner |
| S3 / MinIO endpoint (optional) | | `http://10.0.0.2:9000` | Longhorn backup, csi-s3, Barman |
| S3 bucket | | `k8s-backups` | backups |
| Longhorn replica count | | `1` on one worker, `3` if you have three | Longhorn settings |

Replace globally after you have the table:

```bash
# from the repo root — review the diff
rg -n 'YOUR_GITHUB|CHANGEME|example.com|10.0.0' -g '!docs/**'
```

`docs/` keeps the examples on purpose. Do not “fix” those to your lab IPs if you publish the guide.

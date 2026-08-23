# Fill-in inventory

Do this **before** editing YAML. Every `CHANGEME` in the repo maps to a row here.

| Item | Your value | Example | Used by |
|------|------------|---------|---------|
| GitHub repo URL | | `https://github.com/you/homelab-gitops-starter.git` | Every Application `repoURL` |
| Cluster name | | `k8s` | Talos `gen config` (`~/talos/k8s`) |
| LAN CIDR | | `192.168.1.0/24` | Talos routes, mental model |
| Gateway | | `192.168.1.1` | Talos default route, DNS upstream |
| Control plane IP | | `192.168.1.10` | API `https://IP:6443` |
| Worker IP(s) | | `192.168.1.11` | Nodes, Longhorn |
| Kubernetes API | | `https://192.168.1.10:6443` | kubeconfig, Talos |
| MetalLB pool (apps) | | `192.168.1.200-192.168.1.210` | `values/metallb` |
| Ingress VIP | | `192.168.1.200` | nginx-ingress LoadBalancer |
| LAN resolver (DHCP DNS) | | `192.168.1.1` | Router / Pi-hole; must forward the cluster zone |
| DNS zone (internal) | | `k8s.home.example.com` | BIND + external-dns + Step-CA names |
| DNS zone (public, optional) | | `k8s.example.com` | Let's Encrypt hostnames |
| BIND / RFC2136 host | | `192.168.1.2` | Authoritative for the internal zone |
| TSIG key name | | `externaldns-key` | external-dns (seal the secret) |
| ACME email | | `you@example.com` | Let's Encrypt ClusterIssuer |
| Step-CA URL | | `https://192.168.1.2:9005` | step-issuer; skip only if no LAN names |
| NFS server + path (optional) | | `192.168.1.2:/mnt/user/k8s` | nfs-provisioner |
| S3 / MinIO endpoint (optional) | | `http://192.168.1.2:9000` | Longhorn backup, csi-s3, Barman |
| S3 bucket | | `k8s-backups` | backups |
| Longhorn replica count | | `1` on one worker, `3` if you have three | Longhorn settings |

Replace globally after you have the table:

```bash
# from the repo root — review the diff
rg -n 'YOUR_GITHUB|CHANGEME|example.com|192.168.1' -g '!docs/**'
```

`docs/` keeps the examples on purpose. Do not “fix” those to your lab IPs if you publish the guide.

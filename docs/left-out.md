# What we left out on purpose

| Topic | Why it is not in v1 |
|-------|---------------------|
| TeslaMate, Authentik, Immich, game servers | Workloads. Add them as wave 10+ in your copy. |
| Pi-hole | LAN DNS choice, not a cluster dependency. Point Talos at the router. |
| In-cluster Step-CA | Extra failure domain. Run CA on the NAS or skip. |
| Descheduler | Optional insurance after drains. Not needed to get a lab online. |
| CNPG `instances: 2+` | Extra PVCs and Longhorn replicas. One instance is enough to learn the operator. |
| Cilium / NetworkPolicy | Talos default CNI is Flannel, which **does not enforce** NetworkPolicy. Switching CNI is a cluster rebuild decision. |
| kube-vip / BGP | MetalLB L2 matches a typical homelab LAN. |
| Custom Pages domain | `https://jslay88.github.io/homelab-gitops-starter/` is enough. |
| Someone's live SealedSecrets, IPs, or ACME email | This repo must stay safe to fork. |

If you want those later, add them in **your** template instance, not as a PR that re-homes a private lab into this guide.

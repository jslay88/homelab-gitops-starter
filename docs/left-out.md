# What we left out on purpose

| Topic | Why it is not in v1 |
|-------|---------------------|
| Workloads | Anything that is not the platform (UIs, identity, media, games). Wave **11+** in **your** copy (wave 10 is kube-prometheus-stack). SSO for Argo/Grafana too. |
| Pi-hole | LAN DNS choice, not a cluster dependency. Point Talos at the router. |
| In-cluster Step-CA | Extra failure domain. Run CA on the NAS or skip. |
| Descheduler | Optional insurance after drains. Not needed to get a lab online. |
| CNPG `instances: 2+` | Extra PVCs and Longhorn replicas. One instance is enough to learn the operator. |
| Cilium / NetworkPolicy | Talos default CNI is Flannel, which **does not enforce** NetworkPolicy. Switching CNI is a cluster rebuild decision. |
| kube-vip / BGP | The Kubernetes API VIP is **Talos built-in**. App LoadBalancers are MetalLB L2. Neither needs kube-vip on a flat LAN. |
| Custom Pages domain | `https://jslay88.github.io/homelab-gitops-starter/` is enough. |
| Someone's live SealedSecrets, IPs, or ACME email | This repo must stay safe to fork. |

If you want those later, add them in **your** template instance, not as a PR that re-homes a private lab into this guide. What *is* welcome: [Contributing](contributing.md).

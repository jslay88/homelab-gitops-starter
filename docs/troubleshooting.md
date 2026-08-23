# Troubleshooting

## Argo Application stuck OutOfSync

- **Large CRDs:** set `ServerSideApply=true` (already on Argo CD, CNPG, kube-prometheus-stack).
- **Webhook CA:** MetalLB and cert-manager mutate `caBundle`. `ignoreDifferences` is already set where we have seen this.
- **Deployment `.status`:** Kubernetes 1.35+ adds fields older Argo schemas do not know. Applications that need it have `ServerSideDiff=false` or ignore `.status`.
- **Wrong `repoURL`:** you left `YOUR_GITHUB` in the Application.

## MetalLB has no EXTERNAL-IP

- Nodes and the pool must share L2 (same VLAN/bridge).
- PSA: `metallb-system` must be `enforce=privileged`.
- Speaker DaemonSet not Ready: `kubectl -n metallb-system describe ds`.
- Address already used on the LAN (another VM, Unraid, a reservation).

## Longhorn will not start on Talos

- Image Factory image missing `iscsi-tools` / `util-linux-tools`.
- `kubelet.extraMounts` for `/var/lib/longhorn` missing.
- Kernel modules `iscsi_tcp` / `nbd` not in machine config.
- Namespace not privileged.
- `defaultReplicaCount: 3` on one worker — volumes stay degraded.

## ACME HTTP-01 fails

- Ingress VIP not reachable on port 80 from the internet.
- DNS for the name does not point at that VIP yet (chicken and egg: create the record once, then let external-dns own it).
- You are hitting production LE rate limits — use staging.

## RFC2136 / TSIG

- BIND must allow updates from the **pod CIDR or NAT** the cluster uses, not only the node IPs, depending on how you SNAT.
- Secret key name must match `--rfc2136-tsig-keyname`.
- Clock skew breaks TSIG.

## SealedSecret stays Error

- Sealed with another cluster’s cert.
- Wrong namespace in the SealedSecret vs the target Secret.

## `kubectl top` empty

- metrics-server not Ready; kubelet TLS skip flags are in `values/metrics-server/values.yaml`.

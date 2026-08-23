# Troubleshooting

## Argo Application stuck OutOfSync

- **Large CRDs:** set `ServerSideApply=true` (already on Argo CD, CNPG, kube-prometheus-stack).
- **Webhook CA:** MetalLB and cert-manager mutate `caBundle`. `ignoreDifferences` is already set where we have seen this.
- **Deployment `.status`:** Kubernetes 1.35+ adds fields older Argo schemas do not know. Applications that need it have `ServerSideDiff=false` or ignore `.status`.
- **Wrong `repoURL`:** you left `YOUR_GITHUB` in the Application.

## kubectl dies when one control plane reboots

- kubeconfig `server` is a **node** IP (`https://10.0.0.11:6443`) instead of the API VIP (`https://10.0.0.20:6443`). See [API VIP](talos-unraid.md#kubernetes-api-vip).
- VIP never came up: `ping 10.0.0.20` fails after bootstrap. Check `vip.ip` is on **all three** CP configs and on **no** worker. `talosctl get addresses` on each CP.
- `.20` is also in a MetalLB pool or a DHCP lease — two owners fighting ARP.
- You pointed `talosctl config endpoint` at the VIP and now cannot recover etcd. Point it at `.11` `.12` `.13`.

## MetalLB has no EXTERNAL-IP

- Nodes and the pool must share L2 (same VLAN/bridge).
- PSA: `metallb-system` must be `enforce=privileged`.
- Speaker DaemonSet not Ready: `kubectl -n metallb-system describe ds`.
- Address already used on the LAN (another VM, Unraid, a reservation), or you reused the API VIP `.20` in a pool.

## Longhorn will not start on Talos

- Image Factory image missing `iscsi-tools` / `util-linux-tools`.
- `kubelet.extraMounts` for `/var/lib/longhorn` missing.
- Kernel modules `iscsi_tcp` / `nbd` not in machine config.
- Namespace not privileged.
- `defaultReplicaCount: 3` on one worker — volumes stay degraded.

## ACME HTTP-01 fails

- Ingress VIP not reachable on port 80 from the internet.
- You used a `*.k8s.home.example.com` name. Let's Encrypt cannot see those. Use [Step-CA](step-ca.md).
- Public DNS does not point at that VIP yet (chicken and egg: create the record once, then let external-dns or Cloudflare own it).
- Production LE rate limits — use staging.

## Laptop cannot resolve `*.k8s.home.example.com`

Work top-down. Full map: [local DNS](dns.md).

1. `dig grafana.k8s.home.example.com @<BIND-IP> +norecurse` — if this fails, the zone or record is wrong (BIND, wildcard, or external-dns never wrote the A).
2. `dig grafana.k8s.home.example.com @<router-or-pihole>` — if only this fails, the **domain override / forward** is missing. DHCP clients never talk to BIND directly in topology A.
3. `dig grafana.k8s.home.example.com` with no `@` — if this fails, the laptop is not using the LAN resolver (VPN DNS, hardcoded `1.1.1.1`, phone on LTE).
4. Talos nodes: `machine.network.nameservers` must be the LAN resolver, not only public DNS, or in-cluster lookups of home names fail.

## RFC2136 / TSIG

- Secret `tsig` missing → external-dns CrashLoop.
- `--rfc2136-tsig-keyname` ≠ BIND `key` name.
- `--rfc2136-zone` ≠ `--domain-filter` ≠ the actual zone in `named.conf`.
- Clock skew more than a few minutes.
- BIND logs `REFUSED`: TSIG not sent, or `update-policy` too tight.
- Source IP in the BIND log is a **node** IP (masquerade), not a pod IP. Allow that plus the key; do not open the zone to the whole internet.

## Step-CA / certificates stay Issuing

Full procedure: [Step-CA](step-ca.md).

- Ingress used `cert-manager.io/cluster-issuer: step-issuer`. That looks for a cert-manager ClusterIssuer. Use `issuer` + `issuer-kind: StepClusterIssuer` + `issuer-group: certmanager.step.sm`.
- `caBundle` is not the current root, or is not raw base64 of the PEM.
- `kid` / provisioner name / password mismatch (`step ca provisioner list`).
- Pods cannot reach `https://<ca-host>:9005` (Unraid firewall, wrong IP).
- `duration: 24h` exceeds `maxTLSCertDuration` in `ca.json`.
- Browser warns but Certificate is Ready: root not in **that** device's trust store (Firefox has its own). Hitting the VIP by IP also fails SAN checks.

## SealedSecret stays Error

- Sealed with another cluster’s cert.
- Wrong namespace in the SealedSecret vs the target Secret.

## `kubectl top` empty

- metrics-server not Ready; kubelet TLS skip flags are in `values/metrics-server/values.yaml`.

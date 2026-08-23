# Wave 6 — DNS (in-cluster)

This wave only deploys [external-dns](https://kubernetes-sigs.github.io/external-dns/). It updates BIND. It is **not** a nameserver.

If laptops cannot already resolve `k8s.home.example.com` via your LAN resolver → BIND setup, this Deployment will write records that nobody asks for. Do the [local DNS](../dns.md) page first (zone, TSIG, Unbound/router forward, `dig` from a laptop).

## What this repo ships

One Deployment, RFC2136, **one** zone. Args live in `values/external-dns/deployment.yaml`.

**Must change:**

| Flag / object | Example |
|---------------|---------|
| `--rfc2136-host` | BIND LAN IP (`10.0.0.2`) |
| `--rfc2136-zone` | `k8s.home.example.com` |
| `--domain-filter` | **same** zone |
| `--rfc2136-tsig-keyname` | `externaldns-key` |
| Secret `tsig` / key `secret` | Sealed TSIG secret (see [secrets](../secrets.md)) |

The pod will CrashLoop until that Secret exists. Wave 1 must be Healthy before you seal it.

**Skip:** delete `applications/external-dns.yaml` and use a wildcard A record on the router, as described in the DNS page.

## Cloudflare instead

Replace the args with `--provider=cloudflare` and a sealed API token. Do not leave RFC2136 flags pointing at example IPs. That path updates **public** DNS; it does not create `*.k8s.home.example.com` on the LAN.

## Verify

```bash
kubectl -n external-dns logs deploy/external-dns
# BIND should show UPDATE log lines; then from a laptop:
dig +short grafana.k8s.home.example.com
```

Ownership TXT records use prefix `external-dns-` and owner-id `homelab`. Leave those unique if a second cluster ever shares the zone.

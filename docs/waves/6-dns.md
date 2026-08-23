# Wave 6 — DNS

One [external-dns](https://kubernetes-sigs.github.io/external-dns/) Deployment, RFC2136, **one** zone.

**Must change:** `--rfc2136-host`, `--rfc2136-zone`, `--domain-filter`, TSIG key name. Seal the TSIG secret as `tsig` / key `secret` in namespace `external-dns`.

**Skip:** delete `applications/external-dns.yaml` and create A records yourself.

Cloudflare: replace args with `--provider=cloudflare` and a sealed API token. Do not leave RFC2136 flags pointing at `CHANGEME`.

# Contributing

The public repo is a **template** other people copy. Keep it generic. Your homelab stays in **your** private template instance.

Full guide (same rules, with in-site links): [Contributing](https://jslay88.github.io/homelab-gitops-starter/contributing/).

Stuck? [Get help](https://jslay88.github.io/homelab-gitops-starter/help/) — then [open an issue](https://github.com/jslay88/homelab-gitops-starter/issues/new?template=docs.yml).

## What belongs here

| Yes | No |
|-----|----|
| Doc fixes, missing Validation, broken links | Live IPs, hostnames, ACME email |
| Placeholder YAML (`CHANGEME` / `YOUR_GITHUB` / `10.0.0.0/24`) | SealedSecrets, PATs, TSIG, MinIO keys |
| Chart / image pin bumps **with** `docs/versions.md` | Named workloads (identity, media, games) |
| Upstream doc links | A dump of someone else's `applications/` |

See `docs/left-out.md`. Do not PR those topics in as “v1.”

## Issues first

Open an issue on this repo before a large change. Small doc typos do not need one.

**Fork** to send a PR. That is not how you run the cluster — for your GitOps remote, **Use this template** → private.

## How to work

1. Fork. Branch from `main`.
2. Edit `docs/` and/or placeholders under `applications/` and `values/`.
3. Preview:

   ```bash
   pip install mkdocs-material
   mkdocs serve
   mkdocs build --strict
   ```

4. PR against `main`. Say why. No agent trailers.

Do not commit secrets, kubeconfig, `talosconfig`, or `talosctl gen secrets` output. See [SECURITY.md](SECURITY.md).

## License

MIT.

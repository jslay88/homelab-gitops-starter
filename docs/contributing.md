# Contributing

The public repo is a **template** other people copy. Keep it generic. Your homelab stays in **your** private template instance.

## What belongs here

| Yes | No |
|-----|----|
| Doc fixes, missing Validation, broken links | Live IPs, hostnames, ACME email |
| Placeholder YAML that still says `CHANGEME` / `YOUR_GITHUB` / `10.0.0.0/24` | SealedSecrets, PATs, TSIG, MinIO keys |
| Chart / image pin bumps with the [versions](versions.md) table | Named workloads (identity, media, games) |
| Upstream doc links | A dump of someone else's `applications/` |
| Clarifying Unraid **or** Proxmox hypervisor steps | Re-homing a private lab into this guide |

[What we left out](left-out.md) is intentional. Do not PR those in as “v1.”

## Issues first

Open an issue on [jslay88/homelab-gitops-starter](https://github.com/jslay88/homelab-gitops-starter/issues) before a large change. Small doc typos do not need an issue. How to file: [Get help](help.md).

**Fork** this repo to send a PR. That is the opposite of “Use this template” for *your* GitOps remote — a public fork of the starter is for contributing, not for running the cluster.

## How to work

1. Fork. Branch from `main`.
2. Edit `docs/` and/or placeholders under `applications/` and `values/`.
3. Preview the guide:

    ```bash
    pip install mkdocs-material
    mkdocs serve
    ```

4. `mkdocs build --strict` must pass (same as [Pages CI](https://github.com/jslay88/homelab-gitops-starter/actions)).
5. Open a PR against `main`. Say **why**, not a file list. No agent trailers.

Do not commit `.env`, kubeconfig, `talosconfig`, or `secrets.yaml`. [SECURITY.md](https://github.com/jslay88/homelab-gitops-starter/blob/main/SECURITY.md).

## Pins

Bump `applications/*.yaml` `targetRevision` and the [versions](versions.md) table **together**. Read the chart changelog. One chart per PR if the bump is non-trivial. Procedure: [upgrades](upgrades.md).

## License

MIT. By opening a PR you agree the change is under the same license.

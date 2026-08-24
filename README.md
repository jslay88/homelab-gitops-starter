# Homelab GitOps starter

A **GitOps platform** for a homelab Kubernetes cluster: Argo CD App-of-Apps, sync waves 0–10 (observability is 10), and the external pieces (DNS, CA, NFS, S3) that the cluster cannot provide itself.

This is not a copy of a production lab and not an application catalog. Workloads are out of scope. You add those later in your template copy.

**Guide:** [jslay88.github.io/homelab-gitops-starter](https://jslay88.github.io/homelab-gitops-starter/) — pins and upstream manuals: [versions](https://jslay88.github.io/homelab-gitops-starter/versions/).

## What you get

| Path | Role |
|------|------|
| [docs/](docs/) | MkDocs guide (GitHub Pages) |
| [master-application.yaml](master-application.yaml) | Bootstrap: points Argo CD at `applications/` |
| [applications/](applications/) | One Argo CD Application per platform component |
| [values/](values/) | Helm values and raw manifests — placeholders only |

Argo CD only watches `applications/`. Docs and CI are ignored.

## Quick start

1. **Use this template** (not a fork) and create the new repo as **private**. A public copy will hold your LAN map, SealedSecrets, and ACME email. Argo will need a PAT — see the [guide](https://jslay88.github.io/homelab-gitops-starter/).
2. Replace `YOUR_GITHUB` / `CHANGEME` / `example.com` using the [inventory](https://jslay88.github.io/homelab-gitops-starter/inventory/).
3. Stand up Talos (Unraid VMs are documented; Proxmox works too).
4. `helm install` Argo CD once, create the `repo-creds` Secret, prove the clone in the Argo UI, **then** apply `master-application.yaml`. Git owns the cluster after that.

Delete an Application file under `applications/` to skip that component (NFS, Step-CA, csi-s3, etcd-backup, kube-prometheus-stack, and others are optional).

Agents (Cursor, Claude Code): [AGENTS.md](AGENTS.md). Skills: `.cursor/skills/` and `.claude/skills/`.

## Help and contributing

- [Get help](https://jslay88.github.io/homelab-gitops-starter/help/) — then [open an issue](https://github.com/jslay88/homelab-gitops-starter/issues/new?template=docs.yml)
- [Contributing](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md) before you attach anything to an issue

## License

MIT.

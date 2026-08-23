# Get help

This guide is a starter, not a support contract. Read the page for the step you are on, then the [Validation](waves/index.md) block. Most “Argo is broken” reports are a skipped check.

## Before you open an issue

1. [Troubleshooting](troubleshooting.md) — clone errors, no EXTERNAL-IP, ACME, SealedSecrets, Longhorn.
2. The **Validation** admonition on the page you just left. Do not skip it and file the next wave as a bug.
3. [Bootstrap](bootstrap.md#argo-repo-ui) if Applications show `authentication required` (private repo, PAT, Argo UI **Successful**).
4. An [AI assistant](ai-assistant.md) can run `kubectl` / a Kubernetes MCP server against **your** copy. Do not paste kubeconfig or Secret values into the chat.

If the docs are wrong or a placeholder cannot work as written, that is an issue. If your LAN, Unraid share, or Proxmox bridge is unique, that is your lab.

## Open a GitHub issue

Use the public starter repo, not your private template copy:

**[Open an issue](https://github.com/jslay88/homelab-gitops-starter/issues/new?template=docs.yml)**

Include:

- Which page / wave you were on
- What you did, what you expected, what you got
- Talos / chart pins from [versions](versions.md) if it is a version skew
- **Sanitized** output: `kubectl` / Argo Application status, not full `describe` dumps of Secrets

Do **not** attach or paste: PATs, TSIG, MinIO keys, SealedSecrets, `talosconfig`, `secrets.yaml`, kubeconfig, ACME account keys. See [SECURITY.md](https://github.com/jslay88/homelab-gitops-starter/blob/main/SECURITY.md).

Issues that are “here is my live lab, make it work” will be closed. This repo must stay safe to fork.

## Pull requests

Doc fixes, clearer Validation, and pin bumps belong in a PR. How: [Contributing](contributing.md).

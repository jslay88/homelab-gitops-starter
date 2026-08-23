# AI assistant

An editor agent (Cursor or anything that can run tools) can help **read** this repo, **inspect** the cluster, and **draft** Git changes. It does not replace Argo. Git stays the control plane.

Repo rules for agents: [AGENTS.md](https://github.com/jslay88/homelab-gitops-starter/blob/main/AGENTS.md) (Cursor and Claude). Cursor skills: `.cursor/skills/`. Claude Code: `CLAUDE.md` + `.claude/skills/`.

Two ways to talk to the cluster:

| Tool | What it is | Use when |
|------|------------|----------|
| `kubectl` | CLI on the workstation, same kubeconfig you already use | Default. Works everywhere. |
| [Kubernetes MCP](https://github.com/containers/kubernetes-mcp-server) | MCP server the assistant calls instead of shelling out | You want structured list/get/describe/logs without pasting `kubectl` output into chat |

Either path needs a kubeconfig that already works: `export KUBECONFIG=~/talos/homelab/kubeconfig` and `kubectl get nodes`. If that fails, fix [bootstrap](bootstrap.md) / the [API VIP](talos-unraid.md#kubernetes-api-vip) first. An assistant cannot invent API access.

`talosctl` is **not** Kubernetes. Machine config, upgrades, and etcd snapshots stay on `TALOSCONFIG=~/talos/homelab/_out/talosconfig`. Most Kubernetes MCP servers will not run those commands.

## What to point it at

- **This private GitOps repo** (your template copy), not only the public starter docs.
- The [inventory](inventory.md), [addressing](addressing.md), and [Application sources](argo-sources.md) pages so it does not invent a second App-of-Apps shape.
- Live cluster: `kubectl -n argocd get applications`, `kubectl get ingress,certificate -A`, `kubectl -n <ns> describe pod`.

Ask it to **compare Git to the cluster** (Application Synced? ignoreDifferences? wrong `repoURL`?) before it edits YAML.

## kubectl

Same as you would type. Prefer read-only until you have a Git diff you will commit:

```bash
export KUBECONFIG=~/talos/homelab/kubeconfig
kubectl -n argocd get applications
kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp
```

Writes that belong in Git (Ingress, Application, values) should land as a file change in this repo, then Argo syncs. Do not `helm upgrade` a wave-7-owned release. Do not `kubectl apply` a platform chart that already has an Application.

## Kubernetes MCP

Configure the MCP server with the **same** kubeconfig. In Cursor that is an MCP entry whose command is the kubernetes-mcp binary (or `npx`/container equivalent) and whose env includes `KUBECONFIG`. Other editors have the same idea.

The assistant can then list namespaces, get objects, read logs, and apply *if you allow it*. Treat apply the same as kubectl: platform objects go through Git.

If MCP auth fails, it is almost always the kubeconfig path, a dead API VIP, or RBAC — not the model.

## Do not

- Paste `talosconfig`, `secrets.yaml`, kubeconfig, PATs, TSIG, or MinIO keys into the chat. Point at files; do not dump them.
- Ask it to “just make the repo public so Argo can pull.”
- Let it create `kind: Endpoints` (use [EndpointSlice](lan-backends.md)) or `cert-manager.io/cluster-issuer: step-issuer` (wrong issuer kind).
- Let it skip [edit-in-place](day-2.md#public-ingress-lets-encrypt) on a public Ingress.
- Treat a successful MCP `apply` as GitOps. If it is not in `applications/` / `values/`, the next sync will fight it.

## Good first prompts

- “Applications in `argocd` that are not Healthy. Use kubectl (or Kubernetes MCP). Do not change Git until we agree.”
- “Draft an Ingress + Service + EndpointSlice for a LAN host at `10.0.0.2:443` following [lan-backends](lan-backends.md).”
- “Why is Certificate `whoami-tls` still Issuing? Check cert-manager and step-issuer; do not print Secret data.”

When it is stuck, the [troubleshooting](troubleshooting.md) page is the checklist (skill `troubleshoot-cluster`). The assistant should walk that before inventing a fourth StorageClass.

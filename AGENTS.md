# Agent instructions

This is a **public GitHub template** of cluster-level GitOps (Argo CD App of Apps, waves 0–9). Workloads live in the user’s **private** copy, not here.

Cursor and Claude: read this file. Skills: `.cursor/skills/` (Cursor) and `.claude/skills/` (Claude Code). Human guide: `docs/ai-assistant.md`.

## Hard rules

- **Placeholders only** in this public repo: `YOUR_GITHUB`, `CHANGEME`, `example.com`, addressing `10.0.0.0/24`. Never commit live IPs, SealedSecrets, PATs, TSIG, ACME email, kubeconfig, `talosconfig`, or `talosctl gen secrets` output.
- **Do not name** real lab workloads (identity products, media apps, game servers) in the starter. Day-2 examples stay generic (`whoami`, `my-app`).
- Cluster name is **`homelab`**. Talos files: `~/talos/homelab`.
- **Use this template → private.** Do not tell people to fork for their GitOps remote. Fork is only for PRs back here.
- Git is the control plane. After wave 7, do not `helm upgrade` / `helm uninstall` Argo. Do not `kubectl apply` a platform chart that already has an Application.
- Commits and PRs: no agent trailers (`Made with Cursor`, etc.). Attribute as the user.

## Addressing (do not invent a new map)

| Role | Example |
|------|---------|
| CP nodes | `.11`–`.13` (recommend **3**; skip 2) |
| Kubernetes API VIP | **`.20`** — Talos `machine.network.interfaces[].vip`, **not** MetalLB |
| Workers | `.21`–`.29` |
| Ingress VIP | **`.30`** — MetalLB pool `ingress` `/32` |
| Apps LBs | `.50`–`.99` |

`talosctl gen config` endpoint is `https://10.0.0.20:6443`. `talosctl config endpoint` is the **three node IPs**, never the VIP. WAN 80/443 → ingress VIP, not a node and not `.20`. Do not expose `6443`.

## Bootstrap order

1. Helm install Argo  
2. `kubectl` Secret `repo-creds-github` in `argocd` (`argocd.argoproj.io/secret-type=repo-creds`)  
3. Prove clone in the Argo UI (**Settings → Repositories** = Successful)  
4. **Then** `kubectl apply -f master-application.yaml`  
5. After wave 1, seal that same Secret into Git  

Wave 2 cannot unlock the first clone — those manifests are *in* the private repo.

## Footguns

- Step-CA Ingress: `issuer` + `issuer-kind: StepClusterIssuer` + `issuer-group: certmanager.step.sm`. **Not** `cluster-issuer: step-issuer`.
- Let’s Encrypt: `acme.cert-manager.io/http01-edit-in-place: "true"` and usually `issue-temporary-certificate: "true"`. Self-heal Applications must `ignoreDifferences` that Ingress `/spec/rules` (`RespectIgnoreDifferences=true`) or Argo strips the ACME path.
- LAN backends: selector-less Service + **EndpointSlice** (`discovery.k8s.io/v1`). Not deprecated `Endpoints`.
- Only **metallb** and **step-issuer** Applications ship as chart + raw manifests (three sources). `ref: values` is a file mount, not applied. Argo webhook Ingress / `argocd-secret` patch and Grafana `grafana-admin` get a third source in the **user’s copy**, not in this public repo.
- SealedSecret that targets `argocd-secret` **must** set `sealedsecrets.bitnami.com/patch: "true"`. Replacing that Secret wipes Redis / server keys.
- Do not put `grafana.adminPassword`, Argo bcrypt, or `configs.secret.githubSecret` in Helm values. Seal them.
- Longhorn `defaultReplicaCount`: **1** on one worker, **3** on three disks. Do not recommend 2 as the default.
- Do not `enforce=restricted` on app namespaces in v1.
- Never print Secret values. Point at files.

## Where to look

| Need | Path |
|------|------|
| Pins | `docs/versions.md` |
| Application shapes | `docs/argo-sources.md` |
| Waves / Validation | `docs/waves/` |
| Day-2 Application | `docs/day-2.md` + skill `add-day2-app` |
| Sealing | `docs/secrets.md` + skill `seal-secret` |
| Cluster broken | `docs/troubleshooting.md` + skill `troubleshoot-cluster` |
| Issues | `docs/help.md` — public repo only, no secrets |

If a Validation block on the current page fails, stop. Do not paper over it with the next wave.

## License

MIT (`LICENSE`). Already present. Do not add a second license file.

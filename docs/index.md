# Homelab GitOps starter

A **platform**, not a distro and not an app store.

You get a Kubernetes cluster whose day-2 life is Git: Argo CD watches this repository, syncs Applications in waves, and you add workloads later. The cluster still depends on things **outside** Kubernetes — DNS, a CA, object storage, maybe NFS. Those are documented here so they are not a surprise.

**GitHub:** [jslay88/homelab-gitops-starter](https://github.com/jslay88/homelab-gitops-starter)

## Who this is for

Someone standing up a homelab cluster (Talos on Unraid VMs is the path we write first; Proxmox works) who wants the same *kind* of platform that a long-lived GitOps lab uses: MetalLB, ingress, cert-manager, Longhorn, sealed-secrets, optional Postgres operator and backups.

It is not a dump of someone else's live `cluster-configs`. There are no real IPs, no SealedSecrets, no TeslaMate / Authentik / Immich / game-server charts.

## How to use it

1. Fill in the [inventory](inventory.md) on paper or in a notes file.
2. Use this repo as a **GitHub template**. Replace `YOUR_GITHUB`, `CHANGEME`, and `example.com` in `master-application.yaml` and `applications/`.
3. Build [Talos](talos-unraid.md), then [bootstrap Argo CD](bootstrap.md).
4. Walk [waves 0–9](waves/index.md). Delete Application files you do not want.

## What GitOps means here

```
helm install argocd   (once)
        │
        ▼
master-application.yaml  ──►  applications/*.yaml
                                    │
                                    ▼
                         Helm charts + values/ manifests
```

After the first apply, you do not `helm upgrade` platform charts by hand. You change Git; Argo syncs.

We use **App of Apps** (one YAML file per Application), not ApplicationSet. Homelab platform apps are few and different from each other — Helm-only, raw manifests, extra `ignoreDifferences`. A shared generator fights that.

## Out of scope

Workloads. Identity products. Ad-blocking DNS. A descheduler. Multi-instance Postgres HA. Cilium. Those are [left out on purpose](left-out.md).

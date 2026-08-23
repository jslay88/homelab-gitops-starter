# Homelab GitOps starter

A **platform**, not a distro and not an app store.

You get a Kubernetes cluster whose day-2 life is Git: Argo CD watches this repository, syncs Applications in waves, and you add workloads later. The cluster still depends on things **outside** Kubernetes — DNS, a CA, object storage, maybe NFS. Those are documented here so they are not a surprise.

**GitHub:** [jslay88/homelab-gitops-starter](https://github.com/jslay88/homelab-gitops-starter)

## Who this is for

Someone standing up a homelab cluster (Talos on Unraid VMs is the path we write first; Proxmox works) who wants the same *kind* of platform that a long-lived GitOps lab uses: MetalLB, ingress, cert-manager, Longhorn, sealed-secrets, optional Postgres operator and backups.

It is not a dump of someone else's live lab. There are no real IPs, no SealedSecrets, and no workload charts.

## How to use it

1. Fill in the [inventory](inventory.md) on paper or in a notes file.
2. **Use this template** → new repo, **private**. Do not fork: a fork of a public repo stays public and stays linked. Replace `YOUR_GITHUB`, `CHANGEME`, and `example.com` in `master-application.yaml` and `applications/`. Private Git: create the Argo `repo-creds` Secret **before** the App of Apps ([bootstrap](bootstrap.md#4-create-git-credentials-before-the-app-of-apps)). Wave 2 only seals that Secret into Git later.
3. Read [local DNS](dns.md) and [Step-CA](step-ca.md) **before** you pick hostnames. The cluster cannot invent a LAN nameserver or a private CA.
4. Pick [addresses](addressing.md) (reserved CP / worker / VIP blocks; cluster name `homelab`). **Three control planes** plus a Talos **API VIP** at `.20` so `kubectl` has one IP that survives a CP reboot. Build [Talos](talos-unraid.md) under `~/talos/homelab`, then [bootstrap Argo CD](bootstrap.md).
5. Walk [waves 0–9](waves/index.md). Delete Application files you do not want. Upstream docs for every pin: [versions](versions.md).
6. [First app](first-app.md): one whoami Ingress + Step-CA cert so you know DNS and TLS work.
7. [Talos day-2](talos-day2.md) when you upgrade or add a node. [Backups](waves/9-backups.md) when MinIO exists. [Chart bumps](upgrades.md) when you change a pin.

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

Two Applications are **chart + raw manifests** in one object (MetalLB pools, `StepClusterIssuer`). The rest are chart-only or YAML-only. Breakdown: [Application sources](argo-sources.md).

## Two kinds of hostname

| Kind | Example | DNS | Certificate |
|------|---------|-----|-------------|
| LAN only | `grafana.k8s.home.example.com` | Your BIND / router ([DNS](dns.md)) | [Step-CA](step-ca.md) |
| Public | `app.k8s.example.com` | Public DNS | Let's Encrypt |

If you skip both BIND and Step-CA, you can still reach apps by IP or by `/etc/hosts`, with browser warnings. That is a worse lab.

UIs that already run on the LAN (NAS, router, a Pi) use the same Ingress and the same two cert paths. The backend is a Service plus an [EndpointSlice](lan-backends.md), not a Pod.

## Out of scope

Workloads. Identity products. Ad-blocking DNS as a *cluster* component (Pi-hole can sit in front of BIND later). A descheduler. Multi-instance Postgres HA. Cilium. Those are [left out on purpose](left-out.md).

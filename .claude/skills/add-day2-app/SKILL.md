---
name: add-day2-app
description: >-
  Adds a wave-10+ Argo CD Application (chart+values or manifests) to a
  homelab GitOps repo. Use when adding a day-2 app, Application YAML,
  workload chart, or Ingress in the user's template copy.
---

# Add a day-2 Application

Platform is waves 0–9 plus observability at wave 10. Apps start at wave **11**. Read `docs/day-2.md` and `docs/argo-sources.md`.

## Do this in the user's private copy

Do **not** add workload charts to the public starter (`jslay88/homelab-gitops-starter` as published).

1. Copy the Application shape from `docs/day-2.md` (`applications/my-app.yaml`).
2. Two sources for chart + values (`ref: values` is **not** applied). Third `path: …/manifests` when you need a CR, SealedSecret, or extra Ingress the chart does not create.
3. `repoURL` matches the other Applications (their private repo). `sync-wave: "11"` or higher.
4. Namespace: add PSS labels in `values/namespaces/` if they should exist before the app (wave 0), or `CreateNamespace=true`.
5. Ingress only after `docs/first-app.md` already worked.

## Annotations

- LAN / Step-CA: `issuer` + `issuer-kind: StepClusterIssuer` + `issuer-group: certmanager.step.sm`. Not `cluster-issuer: step-issuer`.
- Public / Let’s Encrypt: `cluster-issuer: letsencrypt` plus `acme.cert-manager.io/http01-edit-in-place: "true"` and `issue-temporary-certificate: "true"`. On a self-heal Application, `ignoreDifferences` that Ingress `/spec/rules` and set `RespectIgnoreDifferences=true`.
- LAN host that is not a Pod: Service **without** selector + `EndpointSlice` (`discovery.k8s.io/v1`). See `docs/lan-backends.md`.

## Do not

- `helm install` / `kubectl apply` a chart that should be an Application.
- Recommend Longhorn replica **2** as the default (1 or 3).
- Commit live IPs or Secrets into the public starter.

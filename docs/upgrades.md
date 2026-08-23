# Bumping charts and pins

Pins live in two places: `applications/*.yaml` `targetRevision` and the [versions](versions.md) table. Bump them **together**. Do not float `latest`.

This is not a Talos upgrade. OS/Kubernetes: [Talos day-2](talos-day2.md).

## Order that has bitten people

1. Read the chart / project **changelog** (linked from [versions](versions.md)).
2. If the project ships CRDs separately (cert-manager, Argo, CNPG, kube-prometheus-stack), know whether the Helm chart applies them (`crds.enabled: true` on cert-manager here).
3. Change `targetRevision` on that Application. Change [versions](versions.md). Commit. Let Argo sync **that** app.
4. Watch `kubectl -n argocd get app <name>` and the controller pods. One chart at a time.

Do not bump Longhorn, Argo, and kube-prometheus-stack in one commit on a Sunday.

## App-specific notes

| App | Watch |
|-----|--------|
| **cert-manager** | Chart has `crds.enabled: true`. Still read the [upgrade notes](https://cert-manager.io/docs/installation/upgrade/). Webhook `caBundle` ignoreDifferences already set. |
| **Argo CD** | Wave 7 **is** the release. Bumping `targetRevision` *is* the upgrade. `ServerSideApply=true` stays. Do not `helm upgrade` beside it. |
| **MetalLB** | CRDs + webhook. Pools in `values/metallb/manifests/` are yours; they survive a chart bump. |
| **Longhorn** | `preUpgradeChecker.jobEnabled: false` (Argo). Follow [Longhorn upgrade](https://longhorn.io/docs/1.12.1/deploy/upgrade/). Engine image rolls per volume; do not reboot every worker in the same minute. |
| **nginx-ingress** | F5 chart, `nginx.org/` annotations. A major chart bump can rename values. Template locally: `helm template …` against the new version. |
| **CNPG / Barman plugin** | Large CRDs, `ServerSideApply=true`. Plugin version must match what the operator expects. |
| **kube-prometheus-stack** | CRDs are huge. `ServerSideApply=true`. Bump this last; it is noisy. |
| **external-dns** | Image tag in `values/external-dns/deployment.yaml`, not a Helm `targetRevision`. |
| **step-issuer** | Chart bump ≠ Step-CA on Unraid. The CA version is independent. |

## Image Factory / Talos schematic

A new Talos version often wants a new installer tag on the **same** schematic. A new extension set wants a **new** schematic ID. After Factory gives you an ID, every node’s `machine.install.image` must match before `talosctl upgrade`. See [Talos day-2](talos-day2.md).

## If sync hangs

[Troubleshooting](troubleshooting.md): `ServerSideApply`, webhook CA, Deployment `.status`. `argocd app diff <name>` (or the UI) shows whether Git or the live CRD is the liar.

Roll back by reverting the Git commit. That is the point of pinning.

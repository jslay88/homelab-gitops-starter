# Application sources

Every file under `applications/` is one [Argo CD Application](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/). They are not all the same shape. Some render a Helm chart. Some apply YAML from this repo. **Two** do both in one Application: the chart installs the controller, raw manifests install the CRs the chart does not ship.

[Multiple sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple-sources/) is how Argo expresses that. Do not flatten MetalLB’s pools into Helm `extraDeploy` unless you enjoy debugging a string blob.

## Three shapes

| Shape | `spec` | What Argo applies |
|-------|--------|-------------------|
| Chart + values | `sources`: git `ref: values` + Helm chart | Only the chart. The git source is a **file mount** for `valueFiles: [$values/…]`. |
| Chart + values + manifests | same, plus a third source `path: values/<app>/manifests` | Chart **and** every YAML in that directory. |
| Manifests only | `source.path` | That directory (plain YAML or Kustomize). No Helm. |
| Chart only | `source.chart` | Chart defaults. No values file in this repo. |

`ref: values` is easy to misread. That source has **no** `path` and **no** `chart`. Argo does not apply anything from it. It only lets the Helm source read `$values/values/metallb/values.yaml` (and friends) from this git repo.

A third source with `path:` **is** applied. Put CRs there. Do not put Helm `values.yaml` there.

```text
applications/metallb.yaml
        │
        ├─ source 1  ref: values          →  not applied (Helm can read files)
        ├─ source 2  chart: metallb       →  speaker, controller, CRDs
        └─ source 3  path: …/manifests    →  IPAddressPool + L2Advertisement
```

The parent `platform` Application (`master-application.yaml`) is shape “manifests only”: it syncs `applications/*.yaml`. Those child Applications then sync the real workloads. That is [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/).

## Which Application is which

| Application | Wave | Shape | Chart | Extra Git objects |
|-------------|------|-------|-------|-------------------|
| `namespaces` | 0 | Manifests | — | PSS-labeled Namespaces |
| **`metallb`** | 0 | **Chart + manifests** | MetalLB | `IPAddressPool`, `L2Advertisement` |
| `sealed-secrets` | 1 | Chart + values | Sealed Secrets | — |
| `cert-manager` | 2 | Chart + values | cert-manager | — |
| `argocd-repo-creds` | 2 | Manifests | — | SealedSecret (after you add it) |
| `nginx-ingress` | 3 | Chart + values | F5 nginx-ingress | — |
| `letsencrypt` | 4 | Manifests | — | `ClusterIssuer` |
| **`step-issuer`** | 4 | **Chart + manifests** | step-issuer | `StepClusterIssuer` |
| `longhorn` | 5 | Chart + values | Longhorn | — |
| `nfs-provisioner` | 5 | Chart + values | nfs-subdir-external-provisioner | — |
| `csi-s3` | 5 | Chart + values | csi-s3 | — |
| `external-dns` | 6 | Manifests | — | Deployment + RBAC |
| `argocd` | 7 | Chart + values | argo-cd | — |
| `metrics-server` | 8 | Chart + values | metrics-server | — |
| `cloudnative-pg` | 8 | Chart only | cloudnative-pg | — |
| `plugin-barman-cloud` | 9 | Chart only | plugin-barman-cloud | — |
| `etcd-backup` | 9 | Manifests | — | suspended CronJob + ConfigMap |
| `kube-prometheus-stack` | 10 | Chart + values | kube-prometheus-stack | — |

Only **`metallb`** and **`step-issuer`** are chart + raw manifests. Everything else is one or the other.

Why those two: the Helm chart installs a controller and CRDs. The thing you actually configure (address pools, the issuer that talks to Step-CA) is a **custom resource** the chart does not create for you. Leaving that CR in Helm values as a hacky template is worse than a third source.

`letsencrypt` is the same *kind* of object (a `ClusterIssuer`) but there is no Let's Encrypt chart — only YAML — so it stays manifests-only and sits in its own wave after cert-manager CRDs exist.

## Chart + manifests: MetalLB

`applications/metallb.yaml` has three sources. The chart gives you speakers and the CRDs. It does **not** know your LAN.

`values/metallb/manifests/` (applied):

| File | Kind | Why it is not in the chart |
|------|------|----------------------------|
| `pool-ingress.yaml` | `IPAddressPool` | Pinned `/32` for nginx (`10.0.0.30` in the examples) |
| `pool-apps.yaml` | `IPAddressPool` | Dynamic range (`.50`–`.99`) |
| `l2-ingress.yaml` / `l2-apps.yaml` | `L2Advertisement` | Which pool is announced on L2 |
| `kustomization.yaml` | Kustomize list | Argo treats `path` as Kustomize if this file exists |

`values/metallb/values.yaml` is **not** in that directory. It is only read by Helm via `$values`. Chart settings (log level, speaker extras) go there. Pool CIDRs go in the manifests. Do not mix them.

Edit the pools before the first sync. After MetalLB is Healthy: `kubectl get ipaddresspool,l2advertisement -A`.

## Chart + manifests: step-issuer

`applications/step-issuer.yaml` is the same three-source shape.

- Helm source: controller Deployment in `step-issuer`.
- `values/step-issuer/values.yaml`: chart knobs only.
- `values/step-issuer/manifests/issuer.yaml`: the `StepClusterIssuer` (URL, `caBundle`, provisioner `kid`). That object is what cert-manager calls. The chart will not invent it.

The provisioner password is a SealedSecret you add later — still not part of the Helm chart. See [Step-CA](step-ca.md) and [secrets](secrets.md).

## How to read a three-source Application

```yaml
spec:
  sources:
    - repoURL: https://github.com/YOUR_GITHUB/homelab-gitops-starter.git
      targetRevision: main
      ref: values                    # mount only
    - repoURL: https://metallb.github.io/metallb
      chart: metallb
      targetRevision: 0.15.2
      helm:
        releaseName: metallb
        valueFiles:
          - $values/values/metallb/values.yaml
    - repoURL: https://github.com/YOUR_GITHUB/homelab-gitops-starter.git
      targetRevision: main
      path: values/metallb/manifests # applied
```

`$values` is the `ref` name from the first source. The path after `$values/` is from the **root of that git repo**. That is why it is `$values/values/metallb/values.yaml`, not `$values/metallb/values.yaml`.

Argo syncs all sources in one Application. One Synced/Healthy. One prune policy. If the chart is OutOfSync and the pools are fine, you still see one red Application — check the tree for which source drifted.

## When you add a day-2 app

Default to **chart + values** (two sources) or **manifests only** (LAN backends: Service + EndpointSlice + Ingress).

Add a third `path: …/manifests` source only when:

- the chart installs a controller/CRD, and
- you need a cluster-specific CR the chart will never own (pool, issuer, `ObjectStore`, …).

Do not put the Ingress for `my-app` in `values/nginx-ingress/manifests`. That would make the ingress Application own every host. Keep app CRs next to the app.

## Docs

- [Multiple sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple-sources/)
- [Helm value files from another source](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple-sources/#helm-value-files-from-external-git-repository)
- [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)

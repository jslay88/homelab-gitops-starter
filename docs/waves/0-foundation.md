# Wave 0 — Foundation

## namespaces

Pre-creates platform namespaces with [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) labels.

| Namespace | PSS |
|-----------|-----|
| `argocd`, `cert-manager`, `external-dns`, `step-issuer`, `cnpg-system` | warn + audit `restricted` |
| `metallb-system`, `nginx-ingress`, `longhorn`, `nfs-provisioner`, `monitoring` | **enforce `privileged`** |

Talos will refuse MetalLB speakers and Longhorn pods without privileged enforce.

!!! success "Validation"
    `kubectl get ns --show-labels | grep pod-security` shows the privileged namespaces. Do not expect MetalLB or Longhorn to start if `metallb-system` / `longhorn` are not `enforce=privileged`.

## metallb

[MetalLB](https://metallb.io/) Helm chart plus [`IPAddressPool` / `L2Advertisement`](https://metallb.io/configuration/) manifests in the **same** Application (three Argo sources). The chart is the speaker; `values/metallb/manifests/` is your LAN. This lab uses [Layer 2](https://metallb.io/concepts/layer2/), not BGP. Why that split: [Application sources](../argo-sources.md#chart--manifests-metallb).

**Must change:** `values/metallb/manifests/pool-apps.yaml` and `pool-ingress.yaml`. Use the reserved VIP blocks from [addressing](../addressing.md) (`10.0.0.30` ingress, `10.0.0.50-99` apps). Never overlap `.11`–`.19` (CP nodes), `.20` (Kubernetes API VIP), or `.21`–`.29` (workers).

!!! success "Validation"
    Do not install ingress (wave 3) until this is true:

    ```bash
    kubectl -n metallb-system get pods   # controller + speaker Running
    kubectl get ipaddresspool,l2advertisement -A
    # pools ingress + apps, addresses are *your* LAN, not leftover 10.0.0.30 if that is not yours
    ```

    Speakers not Ready → no EXTERNAL-IP later. Wrong pool CIDR → collision or empty VIP.

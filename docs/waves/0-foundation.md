# Wave 0 — Foundation

## namespaces

Pre-creates platform namespaces with [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) labels.

| Namespace | PSS |
|-----------|-----|
| `argocd`, `cert-manager`, `external-dns`, `step-issuer`, `cnpg-system` | warn + audit `restricted` |
| `metallb-system`, `nginx-ingress`, `longhorn`, `nfs-provisioner`, `monitoring` | **enforce `privileged`** |

Talos will refuse MetalLB speakers and Longhorn pods without privileged enforce.

**Verify:** `kubectl get ns --show-labels | grep pod-security`

## metallb

[MetalLB](https://metallb.io/) Helm chart plus [`IPAddressPool` / `L2Advertisement`](https://metallb.io/configuration/) manifests. This lab uses [Layer 2](https://metallb.io/concepts/layer2/), not BGP.

**Must change:** `values/metallb/manifests/pool-apps.yaml` and `pool-ingress.yaml`. Use the reserved VIP blocks from [addressing](../addressing.md) (`10.0.0.30` ingress, `10.0.0.50-99` apps). Never overlap `.11`–`.19` (CP nodes), `.20` (Kubernetes API VIP), or `.21`–`.29` (workers).

**Verify:**

```bash
kubectl -n metallb-system get pods
kubectl get ipaddresspool,l2advertisement -A
```

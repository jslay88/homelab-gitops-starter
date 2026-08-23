# Wave 0 — Foundation

## namespaces

Pre-creates platform namespaces with Pod Security labels.

| Namespace | PSS |
|-----------|-----|
| `argocd`, `cert-manager`, `external-dns`, `step-issuer`, `cnpg-system` | warn + audit `restricted` |
| `metallb-system`, `nginx-ingress`, `longhorn`, `nfs-provisioner`, `monitoring` | **enforce `privileged`** |

Talos will refuse MetalLB speakers and Longhorn pods without privileged enforce.

**Verify:** `kubectl get ns --show-labels | grep pod-security`

## metallb

Helm chart `metallb` plus `IPAddressPool` / `L2Advertisement` manifests.

**Must change:** `values/metallb/manifests/pool-apps.yaml` and `pool-ingress.yaml`. Use the reserved VIP blocks from [addressing](../addressing.md) (`10.0.0.20` ingress, `10.0.0.50-99` apps). Never overlap `.11`–`.19` (CP) or `.21`–`.29` (workers).

**Verify:**

```bash
kubectl -n metallb-system get pods
kubectl get ipaddresspool,l2advertisement -A
```

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

**Must change:** `values/metallb/manifests/pool-apps.yaml` and `pool-ingress.yaml` address ranges. They must be unused IPs on the **same L2** as the nodes.

**Verify:**

```bash
kubectl -n metallb-system get pods
kubectl get ipaddresspool,l2advertisement -A
```

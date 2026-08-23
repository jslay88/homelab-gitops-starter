# Wave 3 — Ingress

**F5 NGINX Ingress** from `ghcr.io/nginx/charts`, not the kubernetes/ingress-nginx chart.

The Service is `type: LoadBalancer` pinned to the MetalLB pool named `ingress`.

**Must change:** nothing if the pool name stays `ingress` and wave 0 pools are correct.

On a single worker, anti-affinity cannot spread two replicas. Either keep `replicaCount: 2` (one stays Pending) or set it to `1`.

**Verify:**

```bash
kubectl -n nginx-ingress get svc nginx-ingress-controller
# EXTERNAL-IP should be the ingress VIP (10.0.0.30 in the examples — not the API VIP)
kubectl get ingressclass
```

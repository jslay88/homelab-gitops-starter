# Wave 3 — Ingress

**[NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/)** (F5 chart `ghcr.io/nginx/charts`), not the kubernetes/ingress-nginx project. Annotations use `nginx.org/…` — [list](https://docs.nginx.com/nginx-ingress-controller/configuration/ingress-resources/advanced-configuration-with-annotations/). Kubernetes [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) API is the same.

The Service is `type: LoadBalancer` pinned to the MetalLB pool named `ingress`.

**Must change:** nothing if the pool name stays `ingress` and wave 0 pools are correct.

On a single worker, anti-affinity cannot spread two replicas. Either keep `replicaCount: 2` (one stays Pending) or set it to `1`.

!!! success "Validation"
    Do not create an Ingress or expect Let's Encrypt / Step-CA until:

    ```bash
    kubectl -n nginx-ingress get svc nginx-ingress-controller
    # EXTERNAL-IP = ingress VIP (10.0.0.30 in the examples — not .20, not <pending>)
    kubectl get ingressclass   # nginx
    curl -sI http://10.0.0.30/   # nginx answers (404 is fine; timeout is not)
    ```

    `<pending>` means wave 0 MetalLB is not actually advertising. Fix that first.

Router / firewall WAN forwards for **80 and 443** (public apps, Let's Encrypt HTTP-01) must point at this VIP, not a worker IP and not `.20`. See [addressing](../addressing.md).

To hang a LAN web UI (Unraid, router, a Pi) off this same Ingress — TLS at nginx, backend not a Pod — see [LAN apps behind Ingress](../lan-backends.md).

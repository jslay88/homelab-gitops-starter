# LAN apps behind Ingress

A UI that already runs on Unraid, the router, a Pi, or some other LAN host is **not** a Pod. You still want one hostname, TLS at nginx, and browsers hitting the [ingress VIP](addressing.md) (`.30` in the examples). Ingress terminates TLS and reverse-proxies to that host.

Do **not** put a LAN IP on `Ingress.spec.rules[].http.paths[].backend`. Ingress only talks to Services.

```text
Laptop
  → DNS (nas.k8s.home.example.com → 10.0.0.30)
  → nginx on the ingress VIP :443   (Step-CA or Let's Encrypt cert)
  → Service (ClusterIP, no selector)
  → EndpointSlice (10.0.0.2:8080)
  → the LAN process
```

Same Service + EndpointSlice whether the name is internal or public. Only the Ingress host and the cert-manager annotations change.

!!! success "Validation"
    Do not add these objects until [wave 3](waves/3-ingress.md) has an EXTERNAL-IP, [first app](first-app.md) already worked for a **Pod** backend, and you can `curl` the LAN process from a **worker** IP (not only from your laptop). If the worker cannot reach `10.0.0.2:8080`, nginx will 502 and it will look like an Ingress bug.

## Objects (Kubernetes 1.35+)

`Endpoints` (`apiVersion: v1`) is **deprecated** (1.33+). Do not create `kind: Endpoints` and hope the control plane mirrors it. Write an [`EndpointSlice`](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/) yourself. The Service is a [selector-less Service](https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors). The edge object is a Kubernetes [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/).

| Object | Role |
|--------|------|
| Namespace | One per LAN app (or a shared `lan-apps` namespace). No privileged PSS needed — there are no Pods. |
| Service | `ClusterIP`, **no `selector`**. This is the name Ingress uses. |
| EndpointSlice | `discovery.k8s.io/v1`. Points at the LAN IP and the **real listen port**. |
| Ingress | Host, TLS secret, backend = that Service. |

Rules that bite:

- Omit `spec.selector` on the Service. If you set one, Kubernetes owns the slices and will overwrite yours (or leave the Service empty).
- Link the slice with label `kubernetes.io/service-name: <service-name>` (same namespace).
- Set `endpointslice.kubernetes.io/managed-by` to something that is **not** `controller` (for example `homelab-gitops`). That label is how you mark a hand-written slice.
- **Port names must match** on the Service port and the EndpointSlice port.
- EndpointSlice `ports[].port` is the port on the LAN host. Service `port` is what Ingress connects to (`ClusterIP:port`). `targetPort` should equal the slice port.
- Endpoint IPs cannot be loopback, link-local, or another Service's ClusterIP.

`ExternalName` is a DNS CNAME, not a proxy. Skip it for this pattern. A MetalLB `LoadBalancer` for an HTTP UI wastes a VIP and skips the TLS story you already built.

## Example: HTTP on the LAN, internal name

NAS UI listens on `10.0.0.2:8080` (plain HTTP). Clients should use `https://nas.k8s.home.example.com` with a [Step-CA](step-ca.md) cert.

`applications/nas-ui.yaml` (wave 10, same shape as [day-2](day-2.md)) pointing at `values/nas-ui`.

`values/nas-ui/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nas-ui
  namespace: nas-ui
spec:
  type: ClusterIP
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 8080
```

`values/nas-ui/endpointslice.yaml`:

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: nas-ui-lan
  namespace: nas-ui
  labels:
    kubernetes.io/service-name: nas-ui
    endpointslice.kubernetes.io/managed-by: homelab-gitops
addressType: IPv4
ports:
  - name: http
    protocol: TCP
    port: 8080
    appProtocol: http
endpoints:
  - addresses:
      - "10.0.0.2"
    conditions:
      ready: true
```

`values/nas-ui/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nas-ui
  namespace: nas-ui
  annotations:
    cert-manager.io/issuer: step-issuer
    cert-manager.io/issuer-kind: StepClusterIssuer
    cert-manager.io/issuer-group: certmanager.step.sm
    nginx.org/ssl-redirect: "true"
    nginx.org/http-redirect-code: "308"
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["nas.k8s.home.example.com"]
      secretName: nas-ui-tls
  rules:
    - host: nas.k8s.home.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nas-ui
                port:
                  name: http
```

`cert-manager.io/cluster-issuer: step-issuer` is still wrong here. Same annotations as an in-cluster app: [Step-CA](step-ca.md).

external-dns (wave 6) will create `nas.k8s.home.example.com A 10.0.0.30` if the zone is set up. Until then, the wildcard A on BIND is enough.

## Example: HTTPS on the LAN

Unraid, OPNsense, and many appliance UIs only speak HTTPS. nginx still terminates the **client** cert (Step-CA or LE). The hop from nginx to the appliance is a second TLS session.

Service and slice use the HTTPS port. Ingress adds `nginx.org/ssl-services` (this is the **F5** nginx chart, not `nginx.ingress.kubernetes.io/backend-protocol`).

```yaml
# Service — port name "https"
spec:
  ports:
    - name: https
      protocol: TCP
      port: 443
      targetPort: 443
```

```yaml
# EndpointSlice — same port name, LAN listen port
ports:
  - name: https
    protocol: TCP
    port: 443
    appProtocol: https
endpoints:
  - addresses:
      - "10.0.0.2"
    conditions:
      ready: true
```

```yaml
# Ingress
metadata:
  annotations:
    cert-manager.io/issuer: step-issuer
    cert-manager.io/issuer-kind: StepClusterIssuer
    cert-manager.io/issuer-group: certmanager.step.sm
    nginx.org/ssl-services: "nas-ui"
    nginx.org/ssl-redirect: "true"
spec:
  # backend service port name: https
```

The appliance's own certificate can be self-signed. Clients never see it. If nginx logs upstream SSL errors, the usual cause is a hostname mismatch on that backend cert — fix the appliance name, or keep using HTTP on the LAN hop if the box allows it.

## Example: public name, Let's Encrypt

Same Service + EndpointSlice. Different host and issuer. WAN **80/443** must already DNAT to the ingress VIP ([addressing](addressing.md)).

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
    acme.cert-manager.io/http01-edit-in-place: "true"
    cert-manager.io/issue-temporary-certificate: "true"
    nginx.org/ssl-redirect: "true"
    nginx.org/http-redirect-code: "308"
    # plus nginx.org/ssl-services if the LAN hop is HTTPS
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["nas.k8s.example.com"]
      secretName: nas-ui-public-tls
  rules:
    - host: nas.k8s.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nas-ui
                port:
                  name: http
```

`http01-edit-in-place` is required here the same as for in-cluster apps: [day-2](day-2.md#public-ingress-lets-encrypt). Without it, the HTTP-01 solver Ingress does not share the pinned L2 VIP.

Do not put the router or the NAS on a public name unless you mean anyone on the internet to reach that UI. HTTP-01 will not mint a cert for `*.k8s.home.example.com`.

You can attach **two** Ingresses to the same Service (one LAN host, one public host) if you want both names.

## Networking that has to work

Ingress pods run on **workers**. Flannel SNATs that traffic to the worker node IP (`.21`–`.29`). The LAN host's firewall must allow those node IPs on the listen port. Allowing only the ingress VIP or the pod CIDR is not enough.

The LAN host needs a **stable** address (DHCP reservation). If `.2` moves, the EndpointSlice is wrong until you edit Git.

From a workstation on the LAN, after sync:

```bash
kubectl -n nas-ui get svc,endpointslice
kubectl -n nas-ui get endpointslice -l kubernetes.io/service-name=nas-ui -o yaml
# Endpoints column on the Service should show 10.0.0.2:8080, not <none>

# from a debug pod (or any pod)
kubectl -n nas-ui run curl --rm -it --restart=Never --image=curlimages/curl -- \
  curl -sv http://nas-ui.nas-ui.svc/

dig +short nas.k8s.home.example.com   # 10.0.0.30
kubectl -n nas-ui get certificate
```

`kubectl get endpoints` still exists and may show a mirrored object. Do not edit that. Edit the EndpointSlice.

## App-specific nginx annotations

This controller is [F5 NGINX Ingress](https://docs.nginx.com/nginx-ingress-controller/) (`nginx.org/…`), not ingress-nginx. Annotation reference: [docs](https://docs.nginx.com/nginx-ingress-controller/configuration/ingress-resources/advanced-configuration-with-annotations/).

| Need | Annotation |
|------|------------|
| LAN hop is HTTPS | `nginx.org/ssl-services: "<service-name>"` |
| WebSockets | `nginx.org/websocket-services: "<service-name>"` |
| Large uploads | `nginx.org/client-max-body-size: "10000m"` |
| Long requests | `nginx.org/proxy-read-timeout: "1800s"` (and send) |
| Force HTTPS to the client | `nginx.org/ssl-redirect: "true"` |

If the app issues redirects to `http://10.0.0.2:8080` or its own LAN hostname, that is the app's "base URL" / reverse-proxy setting. Point it at `https://nas.k8s.home.example.com`. Fighting that only with `Host` headers is fragile.

## What this is not

TCP/UDP listeners that are not HTTP do not go through this Ingress. Give them a MetalLB IP from the **apps** pool, as on the [DNS](dns.md#non-http-loadbalancer-not-ingress) page.

Do not publish `6443` this way. The Kubernetes API already has a [VIP](talos-unraid.md#kubernetes-api-vip).

# First app (prove the path)

Waves Healthy is not the same as “a browser got a real cert.” This page is one throwaway app in **your** template copy. Delete it when you are done. Do not add it to the public starter.

!!! success "Validation"
    Do not create `values/whoami/` until every item is true:

    | Check | Expect |
    |-------|--------|
    | Waves 0–4 in Argo | Synced / Healthy |
    | `kubectl -n nginx-ingress get svc` | EXTERNAL-IP = ingress VIP |
    | `dig +short dummy.k8s.home.example.com` from a **laptop** | that VIP (wildcard is enough) |
    | `kubectl get stepclusterissuer` | Ready |
    | Laptop trust store | [Step-CA](step-ca.md) **root** installed |

    A missing row is a [wave](waves/index.md) / [DNS](dns.md) / [Step-CA](step-ca.md) problem. This page will not fix it.

## 1. Namespace + whoami

`values/whoami/` in your copy:

```yaml
# values/whoami/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: whoami
resources:
  - ns.yaml
  - deploy.yaml
  - svc.yaml
  - ingress.yaml
```

```yaml
# values/whoami/ns.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: whoami
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted
```

```yaml
# values/whoami/deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
spec:
  replicas: 1
  selector:
    matchLabels: { app: whoami }
  template:
    metadata:
      labels: { app: whoami }
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:v1.10
          ports:
            - containerPort: 80
```

```yaml
# values/whoami/svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: whoami
spec:
  selector: { app: whoami }
  ports:
    - name: http
      port: 80
      targetPort: 80
```

```yaml
# values/whoami/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami
  annotations:
    cert-manager.io/issuer: step-issuer
    cert-manager.io/issuer-kind: StepClusterIssuer
    cert-manager.io/issuer-group: certmanager.step.sm
    nginx.org/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["whoami.k8s.home.example.com"]
      secretName: whoami-tls
  rules:
    - host: whoami.k8s.home.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: whoami
                port:
                  name: http
```

## 2. Application

`applications/whoami.yaml` — manifests only, wave `10`. `path: values/whoami`. Same `repoURL` as the other Applications. `CreateNamespace` optional (the Namespace is in the kustomization).

Push. Wait for the Application to go Healthy. Do not open a browser until the ladder below is green.

## 3. Ladder

```bash
kubectl -n whoami get deploy,svc,ingress,certificate
# Certificate Ready=True

dig +short whoami.k8s.home.example.com
# 10.0.0.30

curl -vI https://whoami.k8s.home.example.com
# issuer = Home Lab CA, HTTP 200
```

!!! success "Validation"
    All three of `Certificate Ready=True`, `dig` = ingress VIP, and `curl` issuer = Home Lab CA must pass before you call the platform done. Browser with the root installed: padlock, whoami headers. If any step fails, use the table — do not add Grafana Ingress on top of a broken whoami.

| Failure | Likely |
|---------|--------|
| Certificate Issuing | [Step-CA](step-ca.md) annotations / `caBundle` / Unraid:9005 |
| `dig` empty | Wildcard missing; external-dns TSIG; LAN forward. [DNS](dns.md) |
| `curl` connection refused | Ingress Service has no EXTERNAL-IP. MetalLB pool / L2 |
| Browser warns, `curl` fine | Firefox store, or you typed `https://10.0.0.30` (no SAN) |
| 404 on the VIP by IP | Expected. SNI needs the hostname |

## 4. Optional: public name

Second Ingress (or a second host on the same one) with `cluster-issuer: letsencrypt`, `http01-edit-in-place`, `issue-temporary-certificate`. Public DNS + WAN 80 to `.30`. Staging first. [Day-2](day-2.md#public-ingress-lets-encrypt).

!!! success "Validation"
    Do not switch the ClusterIssuer to production ACME until: public `dig` for that hostname returns the **WAN** address (or the VIP if you 1:1 NAT), `curl -sI http://<public-name>/.well-known/acme-challenge/probe` hits **this** nginx (not a node), and a **staging** Certificate reached Ready. Production rate limits will punish a broken NAT.

## 5. Tear down

Delete `applications/whoami.yaml` and `values/whoami/`, push. Prune removes the namespace if `prune: true`.

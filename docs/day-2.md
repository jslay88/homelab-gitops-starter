# Day-2 apps

Platform is waves 0–9 (+ observability). Your apps start at wave **10** or higher.

Do **not** put TeslaMate, Authentik, or media charts in this starter. Add a new Application in **your** template copy.

## Pattern

`applications/my-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "10"
spec:
  project: default
  sources:
    - repoURL: https://github.com/YOUR_GITHUB/homelab-gitops-starter.git
      targetRevision: main
      ref: values
    - repoURL: https://example.chart.repo
      chart: some-chart
      targetRevision: "1.2.3"
      helm:
        releaseName: my-app
        valueFiles:
          - $values/values/my-app/values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Add a Namespace in `values/namespaces/` if you want PSS labels before the app syncs (wave 0).

## Internal Ingress (LAN + Step-CA)

Hostname in `k8s.home.example.com`. DNS: [local DNS](dns.md). TLS: [Step-CA](step-ca.md).

`cert-manager.io/cluster-issuer: step-issuer` is **wrong**. StepClusterIssuer is not a cert-manager ClusterIssuer.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/issuer: step-issuer
    cert-manager.io/issuer-kind: StepClusterIssuer
    cert-manager.io/issuer-group: certmanager.step.sm
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["my-app.k8s.home.example.com"]
      secretName: my-app-tls
  rules:
    - host: my-app.k8s.home.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

After sync: `dig +short my-app.k8s.home.example.com` from a laptop should be the ingress VIP, and `kubectl get certificate -n my-app` should be Ready.

## Public Ingress (Let's Encrypt)

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["app.k8s.example.com"]
      secretName: my-app-public-tls
  rules:
    - host: app.k8s.example.com
      # ...
```

The name must resolve **on the internet** to whatever faces port 80 (hairpin or WAN). Staging first.

## Optional CNPG Cluster

After wave 8, a one-instance Cluster is enough for a homelab app:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-app-db
spec:
  instances: 1
  storage:
    size: 8Gi
    storageClass: longhorn
```

Seal the owner password. Do not enable HA (`instances: 2+`) until you have disk and a reason.

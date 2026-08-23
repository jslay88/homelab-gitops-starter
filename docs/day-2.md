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

## First Ingress + Certificate

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["app.k8s.example.com"]
      secretName: my-app-tls
  rules:
    - host: app.k8s.example.com
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

If you use Step-CA, set `cert-manager.io/cluster-issuer: step-issuer` (match the issuer name you created) and an internal hostname.

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

# Day-2 apps

Platform is waves 0–9 (+ observability). Your apps start at wave **10** or higher.

!!! success "Validation"
    Do not add a workload Ingress until [first app](first-app.md) already showed Certificate Ready, `dig` = ingress VIP, and a browser padlock. A second hostname on a broken path is not a test.

Do **not** add workload charts to this starter repo. Add a new Application in **your** template copy.

## Pattern

Most day-2 apps are **chart + values** (two sources) or **manifests only**. Only add a third `path: …/manifests` source when a chart installs a controller and you still need a CR it will not create. Full table: [Application sources](argo-sources.md).

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
      - RespectIgnoreDifferences=true
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
    acme.cert-manager.io/http01-edit-in-place: "true"
    cert-manager.io/issue-temporary-certificate: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts: ["app.k8s.example.com"]
      secretName: my-app-public-tls
  rules:
    - host: app.k8s.example.com
      # ...
```

`http01-edit-in-place` is required on this stack ([cert-manager Ingress annotations](https://cert-manager.io/docs/usage/ingress/#supported-annotations)). Without it, cert-manager creates a **second** Ingress for `/.well-known/acme-challenge`. F5 nginx does not merge two Ingresses for the same host the way you need, and that solver object is not the Service that owns the pinned MetalLB `/32`. Let's Encrypt's HTTP-01 then never hits the ingress VIP. Edit-in-place adds the challenge path to **this** Ingress so port 80 on `.30` serves it.

`issue-temporary-certificate` gives nginx a self-signed secret so the Ingress is accepted while ACME runs. Drop it and the controller may ignore the host until `tls.secretName` exists — which never happens, because the challenge never ran.

`selfHeal: true` will strip the ACME path cert-manager adds under `spec.rules`. Ignore that Ingress on the Application (same as [Argo webhook](waves/7-argocd.md#github-webhook)). `RespectIgnoreDifferences=true` is already on the example Application above.

```yaml
ignoreDifferences:
  - group: networking.k8s.io
    kind: Ingress
    name: my-app   # metadata.name of the public Ingress
    jsonPointers:
      - /spec/rules
```

The name must resolve **on the internet** to whatever faces port 80 (WAN DNAT to the ingress VIP). Staging first. Step-CA Ingresses do **not** need these two annotations or this ignore.

Argo’s GitHub webhook is the path-only version of this: a **second** public Ingress on `/api/webhook` Exact, UI stays on the LAN. [Wave 7](waves/7-argocd.md#github-webhook).

## LAN hosts that are not Pods

Unraid, the router, a Pi, or any other box on the LAN is an Ingress → Service → **EndpointSlice** (not the deprecated `Endpoints` object). nginx still terminates TLS. Full walkthrough: [LAN apps behind Ingress](lan-backends.md).

## Optional CNPG Cluster

After wave 8, a one-instance [Cluster](https://cloudnative-pg.io/documentation/current/cloudnative-pg.v1/#cluster) is enough for a homelab app:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-app-db
spec:
  instances: 1
  storage:
    size: 8Gi
    storageClass: longhorn   # not nfs, not csi-s3 — see storage wave
```

Seal the owner password (`bootstrap.initdb.secret.name`). Do not enable HA (`instances: 2+`) until you have disk and a reason.

App pods get a user/database from that Cluster (or a `Role` / extra `Database` CR in current CNPG). Point the app at `my-app-db-rw` in the same namespace. Do not put the Superuser password in the app Deployment.

## CNPG backup to MinIO

Wave 9 installs the [Barman Cloud plugin](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/). Per database, in the **app** namespace (third source or a manifests-only Application):

```yaml
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: my-app-minio
  namespace: my-app
spec:
  retentionPolicy: "7d"
  configuration:
    destinationPath: s3://cnpg-backups/my-app
    endpointURL: http://10.0.0.2:9000
    s3Credentials:
      accessKeyId:
        name: cnpg-barman-s3
        key: ACCESS_KEY_ID
      secretAccessKey:
        name: cnpg-barman-s3
        key: ACCESS_SECRET_KEY
    wal:
      compression: gzip
    data:
      compression: gzip
```

```yaml
# on the Cluster
spec:
  instances: 1
  plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: my-app-minio
```

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: my-app-db-daily
  namespace: my-app
spec:
  immediate: true
  schedule: "0 0 3 * * *"   # CNPG is six-field cron (seconds first)
  backupOwnerReference: self
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
  cluster:
    name: my-app-db
```

Seal `cnpg-barman-s3` in `my-app`. Restore is a new Cluster with `bootstrap.recovery` pointing at that ObjectStore — follow current [plugin usage](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/), it moves between versions. Test recovery **once** on a dummy Cluster before the disk you care about dies.

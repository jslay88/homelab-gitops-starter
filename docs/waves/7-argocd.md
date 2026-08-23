# Wave 7 — Argo CD self-manage

The same [Argo CD](https://argo-cd.readthedocs.io/en/stable/) Helm chart you installed by hand, now an Application (chart + values only — no extra manifests). [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) and [sync waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/) are how this repo is structured. Source shapes: [Application sources](../argo-sources.md). After this syncs, change Argo CD by editing `values/argocd/values.yaml`, not by running `helm upgrade` from the workstation.

`ServerSideApply=true` is set because ApplicationSet CRDs are large.

!!! success "Validation"
    `argocd` Application is Synced/Healthy and `helm -n argocd list` still shows the release. Port-forward still logs you in as `admin`. Do not `helm upgrade` or `helm uninstall` from the laptop after this — Git owns the chart.

## Ingress (after DNS + Step-CA)

Default values leave the UI on port-forward. When you want `https://argocd.k8s.home.example.com`, add to `values/argocd/values.yaml` ([chart ingress](https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/README.md)):

```yaml
global:
  domain: argocd.k8s.home.example.com

configs:
  params:
    server.insecure: true   # TLS at nginx, not the Argo process

server:
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      cert-manager.io/issuer: step-issuer
      cert-manager.io/issuer-kind: StepClusterIssuer
      cert-manager.io/issuer-group: certmanager.step.sm
      nginx.org/ssl-redirect: "true"
    hostname: argocd.k8s.home.example.com
    tls: true
    extraTls:
      - hosts:
          - argocd.k8s.home.example.com
        secretName: argocd-server-tls
```

`server.insecure: true` means Argo serves HTTP to nginx; clients still see HTTPS. That is the usual split with this ingress. Do not also enable SSL passthrough unless you know you want it.

!!! success "Validation"
    Do not enable this Ingress until [DNS](../dns.md) `dig argocd.k8s.home.example.com` returns the ingress VIP and [step-issuer](4-issuers.md) is Ready. Then: Certificate `argocd-server-tls` Ready, browser with the [root](../step-ca.md) installed, padlock. If you only have port-forward, leave `ingress.enabled` off.

Admin password is still the initial Secret until you rotate it (Argo UI or `argocd account update-password`). Do not commit it.

SSO is [left out](../left-out.md). Add it in your copy when you have an IdP.

## Do not helm uninstall

The wave 7 Application owns the same release. `helm uninstall argocd` after Git took over will fight Argo.

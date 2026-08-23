# Wave 7 — Argo CD self-manage

The same [Argo CD](https://argo-cd.readthedocs.io/en/stable/) Helm chart you installed by hand, now an Application. [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) and [sync waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/) are how this repo is structured. After this syncs, edit `values/argocd/values.yaml` for HA, ingress, or SSO — do not `helm upgrade` from the workstation.

`ServerSideApply=true` is set because ApplicationSet CRDs are large.

**Verify:** the `argocd` Application is Synced/Healthy and `helm -n argocd list` still shows the release.

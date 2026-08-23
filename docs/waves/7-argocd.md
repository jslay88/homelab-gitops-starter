# Wave 7 — Argo CD self-manage

The same Helm chart you installed by hand, now an Application. After this syncs, edit `values/argocd/values.yaml` for HA, ingress, or SSO — do not `helm upgrade` from the workstation.

`ServerSideApply=true` is set because ApplicationSet CRDs are large.

**Verify:** the `argocd` Application is Synced/Healthy and `helm -n argocd list` still shows the release.

# Wave 1 — Sealed Secrets

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) controller in `kube-system` (`fullnameOverride: sealed-secrets-controller`).

The **sealing certificate is generated in-cluster**. It is unique to this cluster. You cannot reuse SealedSecrets from another lab.

Next: [Secrets workflow](../secrets.md).

**Verify:** `kubectl -n kube-system get deploy sealed-secrets-controller`

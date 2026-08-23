# Wave 4 — Issuers

## letsencrypt

ClusterIssuer using ACME HTTP-01 and ingress class `nginx`.

**Must change:** `email` in `values/letsencrypt/issuer.yaml`.

Use the [staging ACME directory](https://letsencrypt.org/docs/staging-environment/) until HTTP-01 works, then switch to production.

**Skip** if you will not publish names. Delete `applications/letsencrypt.yaml`.

## step-issuer (optional)

Helm chart plus a `StepClusterIssuer` that points at an **external** Step-CA.

**Must change:** CA URL, `caBundle`, provisioner `kid` in `values/step-issuer/manifests/issuer.yaml`. Seal the provisioner password; do not commit it.

**Skip** if you are Let's Encrypt-only. Delete `applications/step-issuer.yaml`.

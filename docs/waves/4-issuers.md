# Wave 4 — Issuers

cert-manager (wave 2) is installed. This wave only adds **issuers**: who is allowed to sign a Certificate.

You almost always want **one** of these for day one, not neither.

## letsencrypt (public names)

ClusterIssuer using ACME HTTP-01 and ingress class `nginx`.

**Must change:** `email` in `values/letsencrypt/issuer.yaml`.

Use the [staging ACME directory](https://letsencrypt.org/docs/staging-environment/) until a test Ingress on a **public** hostname succeeds, then switch `server` to production. Staging certs are not trusted by browsers; that is expected.

HTTP-01 means: Let's Encrypt connects to `http://<name>/.well-known/acme-challenge/...` and that must hit **this** ingress VIP on port 80. The name must already resolve in **public** DNS. A LAN-only name will sit in `Pending` forever.

**Skip** if you will not publish names. Delete `applications/letsencrypt.yaml`.

**Verify:**

```bash
kubectl get clusterissuer letsencrypt
kubectl describe clusterissuer letsencrypt
```

## step-issuer (LAN names)

This is optional in the Application list and **not** optional if you want `https://grafana.k8s.home.example.com` without a browser warning.

The chart is only the controller. The `StepClusterIssuer` points at Step-CA **outside** the cluster. The CA, provisioner password, `caBundle`, client trust, and the correct Ingress annotations are all on the [Step-CA](../step-ca.md) page — read that before filling YAML.

**Must change** in `values/step-issuer/manifests/issuer.yaml`:

| Field | Where it comes from |
|-------|---------------------|
| `spec.url` | `https://<unraid-or-ca-ip>:9005` |
| `spec.caBundle` | `base64 -w0 < root_ca.crt` |
| `provisioner.name` | Same as `step ca init --provisioner` |
| `provisioner.kid` | `step ca provisioner list` |
| Secret `step-issuer-provisioner-password` | Seal; do not commit plaintext |

**Skip** if you are Let's Encrypt-only. Delete `applications/step-issuer.yaml`.

**Verify:**

```bash
kubectl get stepclusterissuer
kubectl -n step-issuer get deploy
# After the first Ingress:
kubectl get certificate -A
```

A Ready issuer with no Certificate objects is normal until you create an Ingress or a `Certificate`.

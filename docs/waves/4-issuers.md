# Wave 4 — Issuers

cert-manager (wave 2) is installed. This wave only adds **issuers**: who is allowed to sign a Certificate.

You almost always want **one** of these for day one, not neither.

## letsencrypt (public names)

[Let's Encrypt](https://letsencrypt.org/docs/) [ClusterIssuer](https://cert-manager.io/docs/configuration/acme/) using [ACME HTTP-01](https://cert-manager.io/docs/configuration/acme/http01/) and ingress class `nginx`. Challenge type: [HTTP-01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge).

**Must change:** `email` in `values/letsencrypt/issuer.yaml`.

Use the [staging ACME directory](https://letsencrypt.org/docs/staging-environment/) until a test Ingress on a **public** hostname succeeds, then switch `server` to production. Staging certs are not trusted by browsers; that is expected.

HTTP-01 means: Let's Encrypt connects to `http://<name>/.well-known/acme-challenge/...` and that must hit **this** ingress VIP on port 80. On a typical homelab that is a WAN port-forward (or 1:1 NAT) of **80 → `10.0.0.30`**, not a node and not the API VIP. The name must already resolve in **public** DNS. A LAN-only name will sit in `Pending` forever.

Every public Ingress needs:

```yaml
acme.cert-manager.io/http01-edit-in-place: "true"
cert-manager.io/issue-temporary-certificate: "true"
```

Without edit-in-place, cert-manager spins up a **separate** solver Ingress. That object is not the LoadBalancer that owns the MetalLB `ingress` `/32`, and F5 nginx will not serve the challenge on the same host as your real Ingress. The challenge never reaches `.30`. Edit-in-place patches **your** Ingress instead. The temporary cert keeps nginx from ignoring the host while the secret is still empty. Details and a full example: [day-2](../day-2.md#public-ingress-lets-encrypt).

**Skip** if you will not publish names. Delete `applications/letsencrypt.yaml`.

!!! success "Validation"
    Do not create a public Ingress until:

    ```bash
    kubectl get clusterissuer letsencrypt
    kubectl describe clusterissuer letsencrypt
    # Ready=True. If ACME registration failed, the email / directory URL is still CHANGEME or staging/prod is mixed up.
    ```

    HTTP-01 also needs [wave 3](3-ingress.md) EXTERNAL-IP and WAN 80 → that VIP. A Ready issuer with no public DNS is not enough to issue.

## step-issuer (LAN names)

This is optional in the Application list and **not** optional if you want `https://grafana.k8s.home.example.com` without a browser warning.

The [step-issuer](https://github.com/smallstep/step-issuer) chart is only the controller ([cert-manager tutorial](https://smallstep.com/docs/tutorials/kubernetes-cert-manager/)). The `StepClusterIssuer` is raw YAML in `values/step-issuer/manifests/`, applied as a **third** Argo source next to the chart ([Application sources](../argo-sources.md#chart--manifests-step-issuer)). It points at [Step-CA](https://smallstep.com/docs/step-ca/) **outside** the cluster. The CA, provisioner password, `caBundle`, client trust, and the correct Ingress annotations are all on the [Step-CA](../step-ca.md) page — read that before filling YAML.

**Must change** in `values/step-issuer/manifests/issuer.yaml`:

| Field | Where it comes from |
|-------|---------------------|
| `spec.url` | `https://<unraid-or-ca-ip>:9005` |
| `spec.caBundle` | `base64 -w0 < root_ca.crt` |
| `provisioner.name` | Same as `step ca init --provisioner` |
| `provisioner.kid` | `step ca provisioner list` |
| Secret `step-issuer-provisioner-password` | Seal; do not commit plaintext |

**Skip** if you are Let's Encrypt-only. Delete `applications/step-issuer.yaml`.

!!! success "Validation"
    Do not add a LAN Ingress (or [first app](../first-app.md)) until:

    ```bash
    kubectl -n step-issuer get deploy   # Ready
    kubectl get stepclusterissuer       # Ready=True
    curl -vk https://10.0.0.2:9005/health   # your CA; timeout = pods cannot reach Unraid
    ```

    A Ready issuer with no Certificate objects is normal until you create an Ingress. If the issuer is not Ready, fix `url` / `caBundle` / provisioner Secret — a later Certificate will sit in `Issuing`.

    After the first Ingress: `kubectl get certificate -A` → `Ready=True`.

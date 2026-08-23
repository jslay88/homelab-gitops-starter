# Secrets

Never commit a Kubernetes `Secret` with real data. Never commit `talosconfig`, `secrets.yaml` from `talosctl gen secrets`, or kubeconfig.

## kubeseal workflow

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets#usage) — `kubeseal` encrypts to this cluster’s sealing cert only.

After wave 1 is Healthy:

```bash
kubeseal --fetch-cert --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system > pub-cert.pem

# example: GitHub PAT for Argo
kubectl -n argocd create secret generic repo-creds-github \
  --from-literal=type=git \
  --from-literal=url=https://github.com/YOUR_GITHUB \
  --from-literal=username=git \
  --from-literal=password=ghp_REDACTED \
  --dry-run=client -o yaml \
  | kubeseal --format=yaml --cert=pub-cert.pem \
  > values/argocd-repo-creds/sealed-secret-repo-creds.yaml
```

Label repo-creds so Argo treats them as repository credentials:

```yaml
metadata:
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
```

Add the file to `values/argocd-repo-creds/kustomization.yaml` `resources:`.

## Re-seal on a new cluster

The controller certificate is unique. Ciphertext from another cluster will not decrypt. Generate a new cert fetch and seal again.

## What belongs in Git

| OK | Not OK |
|----|--------|
| SealedSecret YAML | `Secret` with `data:` |
| Placeholder `CHANGEME` | Live TSIG / MinIO keys |
| Chart values without passwords | `.pem` private keys |

See [SECURITY.md](https://github.com/jslay88/homelab-gitops-starter/blob/main/SECURITY.md).

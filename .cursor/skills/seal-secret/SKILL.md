---
name: seal-secret
description: >-
  Seals a Kubernetes Secret with kubeseal for this cluster. Use when creating
  a SealedSecret, repo-creds, TSIG, MinIO keys, or step-issuer password.
---

# Seal a Secret

Read `docs/secrets.md` and `docs/waves/1-sealed-secrets.md`.

## Preconditions

Wave 1 Healthy. `kubeseal --fetch-cert` writes a real PEM. Do not seal if that fails.

```bash
kubeseal --fetch-cert --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system > pub-cert.pem
```

## Seal

Pipe a dry-run Secret into `kubeseal`. Commit **only** the SealedSecret.

```bash
kubectl create secret generic NAME -n NAMESPACE \
  --from-literal=key=VALUE \
  --dry-run=client -o yaml \
  | kubeseal --format=yaml --cert=pub-cert.pem \
  > values/<app>/sealed-secret-NAME.yaml
```

Add the file to that directory’s `kustomization.yaml` `resources:`.

## Repo-creds

Name `repo-creds-github`, namespace `argocd`, label `argocd.argoproj.io/secret-type=repo-creds`. Same object as the bootstrap kubectl Secret. Do not create a second name.

## Do not

- Commit the plaintext Secret or `pub-cert.pem` into a **public** repo (the cert is public-ish; the password is not).
- Print Secret values in chat.
- Reuse ciphertext from another cluster unless the sealing key was restored.
- Tell the user to skip the kubectl Secret and rely on wave 2 for the **first** clone.

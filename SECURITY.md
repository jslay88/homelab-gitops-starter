# Security

This repository is a public **starter**. Your working copy should be a **private** GitHub template (not a public fork). Even then, never commit live unsealed credentials.

## Do not file issues or PRs with

- Unsealed Kubernetes Secrets
- SealedSecret ciphertext from another cluster (it will not decrypt, and it is still a secret)
- TSIG keys, S3/MinIO access keys, GitHub PATs, ACME account keys
- `talosconfig`, `secrets.yaml` from `talosctl gen secrets`, or kubeconfig files
- Longhorn / Step-CA / BIND admin passwords

## How secrets are supposed to work

1. Deploy `sealed-secrets` (wave 1).
2. Fetch that cluster’s sealing certificate.
3. `kubeseal` plaintext locally.
4. Commit only the SealedSecret.

A SealedSecret is bound to **one** cluster. Re-seal everything when you stand up a new cluster.

If you accidentally pushed a secret, rotate it at the source and treat Git history as compromised.

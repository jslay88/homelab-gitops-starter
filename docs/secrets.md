# Secrets

Keep the GitOps repo **private** (Use this template → Private). You will still commit SealedSecrets and LAN YAML; the public internet does not need that map. Argo pulls with a PAT — that is the first row in the catalog below.

Never commit a Kubernetes `Secret` with real data. Never commit `talosconfig`, `secrets.yaml` from `talosctl gen secrets`, or kubeconfig.

## kubeseal workflow

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets#usage) — `kubeseal` encrypts to this cluster’s sealing cert only.

After wave 1 is Healthy:

```bash
kubeseal --fetch-cert --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system > pub-cert.pem
```

Keep `pub-cert.pem` for sealing on the workstation. It is the **public** half. The private half lives in the cluster (next section).

The PAT Secret must already exist on the cluster **before** Argo can clone a private repo. Create it with kubectl during [bootstrap](bootstrap.md#4-create-git-credentials-before-the-app-of-apps). After wave 1, seal **that same** Secret so Git owns it:

```bash
# example: GitHub PAT for Argo (same name as the bootstrap Secret)
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

## Back up the sealing key

If you rebuild the cluster or lose `kube-system`’s sealing Secret, **every SealedSecret in Git is paper**. The ciphertext is bound to that key.

```bash
kubectl -n kube-system get secret \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml > ~/sealed-secrets-key-BACKUP.yaml
chmod 600 ~/sealed-secrets-key-BACKUP.yaml
# copy off the workstation: encrypted disk, password manager attachment, not Git
```

Restore **before** SealedSecrets try to decrypt (or the controller mints a new key):

```bash
kubectl apply -f ~/sealed-secrets-key-BACKUP.yaml
kubectl -n kube-system delete pod -l app.kubernetes.io/name=sealed-secrets
```

Take a new backup after a key rotation.

## Re-seal on a new cluster

The controller certificate is unique. Ciphertext from another cluster will not decrypt. New cert fetch, seal again — unless you restored the old sealing key first (same cluster identity).

## Catalog

Seal each of these **after** wave 1. Namespace must match. Key names must match what the Deployment / CR references.

| Secret | Namespace | Keys | Used by |
|--------|-----------|------|---------|
| `repo-creds-github` (name yours) | `argocd` | `type`, `url`, `username`, `password` + label `argocd.argoproj.io/secret-type=repo-creds` | Argo pull of a **private** repo (recommended). |
| `step-issuer-provisioner-password` | `step-issuer` | `password` | `StepClusterIssuer` `provisioner.passwordRef` |
| `tsig` | `external-dns` | `secret` (the TSIG secret bytes, not the key name) | external-dns `TSIG_SECRET` |
| `longhorn-backup-s3` | `longhorn` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINTS` (`http://10.0.0.2:9000`), optionally `AWS_REGION` | Longhorn `defaultBackupStore` |
| `cnpg-barman-s3` | **app namespace** | `ACCESS_KEY_ID`, `ACCESS_SECRET_KEY` | CNPG `ObjectStore` per database |
| `csi-s3-secret` | `kube-system` | `accessKeyID`, `secretAccessKey`, `endpoint` | csi-s3 chart (`secret.create: false`) |
| CNPG owner / app user | app namespace | whatever the `Cluster` `bootstrap.initdb.secret` names | Day-2 database |

TSIG example (key material from `tsig-keygen` / `ddns-confgen` on BIND — [DNS](dns.md)):

```bash
kubectl -n external-dns create secret generic tsig \
  --from-literal=secret='BASE64-OR-HMAC-SECRET-FROM-BIND' \
  --dry-run=client -o yaml \
  | kubeseal --format=yaml --cert=pub-cert.pem \
  > values/external-dns/sealed-secret-tsig.yaml
```

Add that file to `values/external-dns/kustomization.yaml`. The Deployment CrashLoops until it exists.

Step-CA provisioner:

```bash
kubectl -n step-issuer create secret generic step-issuer-provisioner-password \
  --from-literal=password='THE-PROVISIONER-PASSWORD' \
  --dry-run=client -o yaml \
  | kubeseal --format=yaml --cert=pub-cert.pem \
  > values/step-issuer/manifests/sealed-secret-provisioner.yaml
```

Add it to `values/step-issuer/manifests/kustomization.yaml` (that directory is already an Argo source).

Longhorn / MinIO: [backups](waves/9-backups.md). Same seal dance, namespace `longhorn`.

## What belongs in Git

| OK | Not OK |
|----|--------|
| SealedSecret YAML | `Secret` with `data:` |
| Placeholder `CHANGEME` | Live TSIG / MinIO keys / PAT |
| Chart values without passwords | `.pem` private keys, `secrets.yaml`, kubeconfig |
| `pub-cert.pem` if you want (public) | `sealed-secrets-key-BACKUP.yaml` |

See [SECURITY.md](https://github.com/jslay88/homelab-gitops-starter/blob/main/SECURITY.md).

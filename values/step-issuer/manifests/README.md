Fill `issuer.yaml` from `step ca provisioner list` on the host that runs Step-CA.

Seal:

```bash
kubectl -n step-issuer create secret generic step-issuer-provisioner-password \
  --from-literal=password=CHANGEME \
  --dry-run=client -o yaml \
  | kubeseal --format=yaml --cert=pub-cert.pem \
  > values/step-issuer/manifests/sealed-secret-provisioner.yaml
```

Add that file to `kustomization.yaml`.

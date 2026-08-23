Create the BIND zone and LAN forward first: the guide page "Local DNS and routing".

Seal the TSIG secret before this Deployment will stay Ready:

```bash
kubectl -n external-dns create secret generic tsig \
  --from-literal=secret=CHANGEME \
  --dry-run=client -o yaml \
  | kubeseal --format=yaml --cert=pub-cert.pem \
  > values/external-dns/sealed-secret-tsig.yaml
```

Add it to `kustomization.yaml`.

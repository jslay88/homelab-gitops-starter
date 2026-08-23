Do not enable this Application until MinIO (or S3) exists.

Expected Secret keys (chart-dependent; confirm against csi-s3 0.43.x):

```yaml
stringData:
  accessKeyID: CHANGEME
  secretAccessKey: CHANGEME
  endpoint: http://192.168.1.2:9000
```

Seal into `kube-system` as `csi-s3-secret`.

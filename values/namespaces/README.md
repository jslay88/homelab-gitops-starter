Platform namespaces only. For an app namespace, copy `ns-argocd.yaml`, rename it, and add the file to `kustomization.yaml`.

Use restricted warn/audit for apps. Use privileged enforce only when the workload needs it (CSI, ingress, MetalLB, node exporters).

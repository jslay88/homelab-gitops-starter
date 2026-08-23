# Bootstrap Argo CD

Manual steps happen **once**. After that, Git is the control plane.

## 0. DNS and CA are not optional surprises

If you want `https://something.k8s.home.example.com` from a laptop, finish [local DNS](dns.md) (zone + forward + `dig`) and have [Step-CA](step-ca.md) listening **before** you care about wave 4/6. You can bootstrap Argo without them; Ingresses will just not be useful.

## 1. Point kubectl at the cluster

Configs from the Talos chapter live under `~/talos/homelab`:

```bash
export KUBECONFIG=~/talos/homelab/kubeconfig
export TALOSCONFIG=~/talos/homelab/_out/talosconfig
kubectl config view --minify | grep server
# expect the API VIP: https://10.0.0.20:6443
kubectl get nodes
```

If `server` is a node IP (`10.0.0.11`), you generated the cluster against the wrong endpoint. Fix that in Talos before you rely on maintenance: [API VIP](talos-unraid.md#kubernetes-api-vip).

## 2. Install Argo CD (Helm, one shot)

Chart docs: [Argo CD](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/). After wave 7, Git owns this release.

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd
helm install argocd argo/argo-cd \
  --namespace argocd \
  --version 8.6.0 \
  --set server.service.type=ClusterIP
```

Wait until pods are Ready:

```bash
kubectl -n argocd get pods
```

Initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

Port-forward if you want the UI before ingress exists:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

## 3. Replace placeholders in Git

In **your** template copy of this repo:

- `YOUR_GITHUB` → your GitHub user/org (every `repoURL` that points at this repo)
- Inventory values in `values/` (MetalLB pools, ACME email, NFS, Step-CA, DNS)

Commit and push to `main`.

## 4. Apply the App of Apps

```bash
kubectl apply -f master-application.yaml
```

That Application watches `applications/` and creates one child per YAML file.

```bash
kubectl -n argocd get applications
```

Waves 0–2 should go Healthy first. Ingress (wave 3) needs MetalLB. Certificates need cert-manager CRDs.

## 5. Private Git

If the repo is private, seal a PAT and add it under `values/argocd-repo-creds/` **before** wave 2 can pull. Public repos can delete `applications/argocd-repo-creds.yaml`.

## 6. Self-manage

Wave 7 adopts this Helm release into Git. After it syncs, change Argo CD by editing `values/argocd/values.yaml`, not by running `helm upgrade` on your laptop.

!!! warning "Do not helm uninstall"
    The wave 7 Application owns the same release. `helm uninstall argocd` after Git took over will fight Argo.

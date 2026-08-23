# Bootstrap Argo CD

Manual steps happen **once**. After that, Git is the control plane.

**Private repo (recommended):** Argo must already have a `repo-creds` Secret **before** you apply `master-application.yaml`. That file tells Argo to clone your repo. Wave 2 cannot help — those manifests are *in* the repo. Order: Helm install → kubectl Secret → App of Apps. Details in [step 4](#4-create-git-credentials-before-the-app-of-apps).

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

!!! success "Validation"
    Do not install Argo until `kubectl get nodes` shows every node **Ready** and `server` is `https://10.0.0.20:6443`. Four nodes for the recommended topology (3 CP + 1 worker).

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

Open `https://localhost:8080` (self-signed — accept it). Username `admin`, password from the Secret above.

!!! success "Validation"
    Do not create repo credentials until every pod in `argocd` is Ready and you can log into that UI. If the UI never loads, Argo is not up; a later Application will not save you.

## 3. Replace placeholders in Git

In **your** private template copy of this repo:

- `YOUR_GITHUB` → your GitHub user/org (every `repoURL` that points at this repo)
- Inventory values in `values/` (MetalLB pools, ACME email, NFS, Step-CA, DNS)

Commit and push to `main`.

!!! success "Validation"
    `grep -R YOUR_GITHUB applications/ master-application.yaml` must return nothing. `git remote -v` must be **your private** repo, not `jslay88/homelab-gitops-starter`. Do not create credentials that point at the public starter.

## 4. Create Git credentials — before the App of Apps

Do this **now**. Do **not** skip to step 5.

`master-application.yaml` tells Argo to clone **your** private repo and apply `applications/`. Argo has no GitHub credentials yet. Wave 2 (`argocd-repo-creds`) cannot save you: that Application YAML *is inside the private repo*. Sealed Secrets is not installed yet either. Create the Secret **on the cluster** with kubectl, then apply the App of Apps.

1. GitHub → Settings → Developer settings → Personal access tokens. Classic: scope `repo`. Fine-grained: **Contents: Read** on this one repository. Do not commit the token.
2. The `url` is a **prefix**. `https://github.com/YOUR_GITHUB` covers every repo under that user/org. Narrower is fine (`https://github.com/YOUR_GITHUB/homelab-gitops.git`).

```bash
# once, on the workstation — not in Git
kubectl -n argocd create secret generic repo-creds-github \
  --from-literal=type=git \
  --from-literal=url=https://github.com/YOUR_GITHUB \
  --from-literal=username=git \
  --from-literal=password=ghp_YOUR_TOKEN

kubectl -n argocd label secret repo-creds-github \
  argocd.argoproj.io/secret-type=repo-creds
```

The label is what Argo looks for ([repository credentials](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repository-credentials)). Without it the Secret is just a Secret.

### Validation — Argo UI (blocker for step 5) { #argo-repo-ui }

Do **not** apply `master-application.yaml` until the UI says the private repo is reachable.

1. Port-forward (step 2) if it is not still running. Log in as `admin`.
2. **Settings** (gear) → **Repositories**.
3. **+ Connect Repo** → **VIA HTTPS**.
4. Repository URL: the **full** URL of your private copy, e.g. `https://github.com/YOU/homelab-gitops.git` — not this public starter.
5. Username `git`. Password: the same PAT you put in the Secret.
6. Project `default`. Connect.

The row’s connection status must be **Successful** (green). That is the only proof the token can clone. A Secret that exists but has the wrong URL, missing `repo` scope, or no `repo-creds` label will fail here.

You can leave that connected-repo row; it is a repository entry, not only a credential template. The prefix Secret from kubectl still covers other repos under `https://github.com/YOU`.

If Connect fails: regenerate the PAT, fix `url` / label, `kubectl -n argocd get secret repo-creds-github --show-labels`, try again. Stay on this step.

CLI equivalent (optional):

```bash
argocd login localhost:8080 --insecure
argocd repo add https://github.com/YOU/homelab-gitops.git \
  --username git --password "$GITHUB_TOKEN"
argocd repo get https://github.com/YOU/homelab-gitops.git
# CONNECTION STATE: Successful
```

If you already applied the App of Apps and every Application is `ComparisonError` / `authentication required` / `Repository not accessible`: create the Secret as above, pass this UI check, then **Refresh** the `platform` Application (UI) or:

```bash
kubectl -n argocd annotate application platform argocd.argoproj.io/refresh=hard --overwrite
```

After wave 1 is Healthy, [seal the same PAT](secrets.md) into `values/argocd-repo-creds/` so Git owns the Secret. Use the **same** name (`repo-creds-github`) so you are not maintaining two creds. Until then, the kubectl Secret is the only thing that can clone.

If you ignored the private-repo advice and the copy is public, skip this section and delete `applications/argocd-repo-creds.yaml`. That is not the path this guide recommends.

## 5. Apply the App of Apps

!!! warning "Private repo"
    If `kubectl -n argocd get secret repo-creds-github` fails, **stop**. If the Argo UI Repositories row is not **Successful**, **stop**. Go back to [step 4](#argo-repo-ui). Applying now will sit on `authentication required`.

```bash
kubectl -n argocd get secret repo-creds-github   # must exist
kubectl apply -f master-application.yaml
```

That Application watches `applications/` and creates one child per YAML file. The Secret from step 4 is what lets the first clone succeed.

```bash
kubectl -n argocd get applications
```

Waves 0–2 should go Healthy first. Ingress (wave 3) needs MetalLB. Certificates need cert-manager CRDs. When 0–4 are Healthy and DNS works, prove the path with a [first app](first-app.md).

!!! success "Validation"
    In the UI: **Applications**. `platform` is Synced/Healthy and you see child apps (`namespaces`, `metallb`, …). If `platform` is empty or `ComparisonError`, the clone still failed — back to [step 4](#argo-repo-ui). Do not start [wave 0](waves/0-foundation.md) troubleshooting until `namespaces` exists.

## 6. Self-manage

Wave 7 adopts this Helm release into Git. After it syncs, change Argo CD by editing `values/argocd/values.yaml`, not by running `helm upgrade` on your laptop.

!!! warning "Do not helm uninstall"
    The wave 7 Application owns the same release. `helm uninstall argocd` after Git took over will fight Argo.

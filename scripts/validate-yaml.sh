#!/usr/bin/env bash
# Validate Git-tracked YAML: parse, kustomize build, kubeconform.
# Same checks as .github/workflows/validate.yml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

KUBECONFORM_VERSION="${KUBECONFORM_VERSION:-v0.7.0}"
KUSTOMIZE_VERSION="${KUSTOMIZE_VERSION:-v5.7.1}"
K8S_VERSION="${K8S_VERSION:-1.33.0}"
if [[ -z "${CRDS_CATALOG:-}" ]]; then
  CRDS_CATALOG='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

if ! python3 -c "import yaml" >/dev/null 2>&1; then
  echo "installing PyYAML"
  python3 -m pip install -q pyyaml
fi

TOOLS="$ROOT/.tools"
mkdir -p "$TOOLS"
export PATH="$TOOLS:$PATH"

if ! need_cmd kubeconform; then
  echo "downloading kubeconform ${KUBECONFORM_VERSION}"
  curl -fsSL "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
    | tar -xz -C "$TOOLS" kubeconform
fi

if ! need_cmd kustomize; then
  echo "downloading kustomize ${KUSTOMIZE_VERSION}"
  curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C "$TOOLS" kustomize
fi

echo "== parse (cluster + CI YAML) =="
fail=0
while IFS= read -r f; do
  case "$f" in
    mkdocs.yml) continue ;;  # MkDocs Python tags, not Kubernetes
  esac
  if ! python3 -c "import sys, yaml; list(yaml.safe_load_all(open(sys.argv[1])))" "$f"; then
    echo "INVALID YAML: $f" >&2
    fail=1
  fi
done < <(git ls-files '*.yaml' '*.yml')
if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
echo "ok"

echo "== kustomize build =="
KUST_DIRS=(
  values/namespaces
  values/metallb/manifests
  values/letsencrypt
  values/step-issuer/manifests
  values/external-dns
  values/etcd-backup
  values/argocd-repo-creds
)
for d in "${KUST_DIRS[@]}"; do
  echo "-- $d"
  kustomize build "$d" >/dev/null
done
echo "ok"

echo "== kubeconform (k8s ${K8S_VERSION}) =="
kc() {
  kubeconform \
    -kubernetes-version "$K8S_VERSION" \
    -strict \
    -schema-location default \
    -schema-location "$CRDS_CATALOG" \
    -output text \
    -summary \
    "$@"
}

kc master-application.yaml applications/*.yaml \
  values/argocd-repo-creds/repo-creds.example.yaml

built="$(mktemp --suffix=.yaml)"
trap 'rm -f "$built"' EXIT
for d in "${KUST_DIRS[@]}"; do
  echo "-- $d"
  kustomize build "$d" >"$built"
  # Empty resources: (argocd-repo-creds before a SealedSecret) is valid.
  if [[ ! -s "$built" ]]; then
    continue
  fi
  kc "$built"
done

echo "all yaml checks passed"

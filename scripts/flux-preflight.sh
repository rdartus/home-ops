#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

INCLUDE_ARCHIVE=false
if [[ "${1:-}" == "--include-archive" ]]; then
  INCLUDE_ARCHIVE=true
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[flux-preflight] Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd flux
require_cmd yq

if [[ "$INCLUDE_ARCHIVE" == true ]]; then
  mapfile -t KS_FILES < <(find kubernetes -type f -name 'ks.yaml' | sort)
else
  mapfile -t KS_FILES < <(find kubernetes -type f -name 'ks.yaml' -not -path 'kubernetes/_archive/*' | sort)
fi

if [[ "${#KS_FILES[@]}" -eq 0 ]]; then
  echo "[flux-preflight] No ks.yaml files found."
  exit 0
fi

failures=0
count=0

for file in "${KS_FILES[@]}"; do
  while IFS=$'\t' read -r name namespace path; do
    [[ -z "$name" || -z "$path" ]] && continue

    count=$((count + 1))
    echo "[flux-preflight] Building $namespace/$name from $file"

    if ! flux -n "$namespace" build kustomization "$name" \
      --path "$path" \
      --kustomization-file "$file" \
      --dry-run >/dev/null; then
      echo "  [ERROR] flux build failed for $namespace/$name"
      failures=1
    fi
  done < <(
    yq -r '
      select(
        (.kind == "Kustomization") and
        ((.apiVersion // "") | startswith("kustomize.toolkit.fluxcd.io/"))
      )
      | [
          (.metadata.name // ""),
          (.metadata.namespace // "flux-system"),
          (.spec.path // "")
        ]
      | @tsv
    ' "$file"
  )
done

if [[ "$count" -eq 0 ]]; then
  echo "[flux-preflight] No Flux Kustomization objects found in ks.yaml files."
  exit 0
fi

if [[ "$failures" -ne 0 ]]; then
  echo "[flux-preflight] Failed ($count Kustomization object(s) checked)."
  exit 1
fi

echo "[flux-preflight] OK ($count Kustomization object(s) checked)."

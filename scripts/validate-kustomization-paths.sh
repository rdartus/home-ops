#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

MODE="staged"
if [[ "${1:-}" == "--all" ]]; then
  MODE="all"
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[kustomization-check] Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd yq
require_cmd kubectl

collect_kustomizations() {
  if [[ "$MODE" == "all" ]]; then
    find kubernetes -type f -name 'kustomization.yaml' | sort
  else
    git diff --cached --name-only --diff-filter=ACMR \
      | grep -E '(^|/)kustomization\.yaml$' || true
  fi
}

mapfile -t KUSTOMIZATION_FILES < <(collect_kustomizations)

if [[ "${#KUSTOMIZATION_FILES[@]}" -eq 0 ]]; then
  echo "[kustomization-check] No kustomization.yaml files to validate ($MODE mode)."
  exit 0
fi

extract_refs() {
  local file="$1"
  yq -r '
    def arr(x): if x == null then [] else x end;
    [
      (arr(.resources)[]?),
      (arr(.components)[]?),
      (arr(.crds)[]?),
      (arr(.configurations)[]?),
      (arr(.generators)[]?),
      (arr(.patchesStrategicMerge)[]?),
      (arr(.patches)[]? | .path? // empty),
      (arr(.configMapGenerator)[]? | arr(.files)[]?),
      (arr(.secretGenerator)[]? | arr(.files)[]?)
    ]
    | .[]
  ' "$file"
}

failures=0
checked=0

for kf in "${KUSTOMIZATION_FILES[@]}"; do
  if [[ ! -f "$kf" ]]; then
    echo "[kustomization-check] Missing file in index/worktree: $kf"
    failures=1
    continue
  fi

  checked=$((checked + 1))
  base_dir="$(dirname "$kf")"
  echo "[kustomization-check] Checking references in $kf"

  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue

    if [[ "$ref" == *"="* ]]; then
      ref="${ref#*=}"
    fi

    # Skip remote references
    if [[ "$ref" == *"://"* || "$ref" == git::* ]]; then
      continue
    fi

    ref="${ref#./}"

    if [[ ! -e "$base_dir/$ref" ]]; then
      echo "  [MISSING] $ref"
      failures=1
    fi
  done < <(extract_refs "$kf")

  echo "[kustomization-check] Rendering $(dirname "$kf") with kubectl kustomize"
  if ! kubectl kustomize "$base_dir" >/dev/null; then
    echo "  [ERROR] kubectl kustomize failed for $base_dir"
    failures=1
  fi
done

if [[ "$failures" -ne 0 ]]; then
  echo "[kustomization-check] Validation failed."
  exit 1
fi

echo "[kustomization-check] Validation passed for $checked file(s)."

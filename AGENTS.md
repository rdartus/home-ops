<!-- bmad:context -->
<!-- Verified 2026-10-01 against d904b9bf17b31accec037ba42ac5a412fbd29764. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## home-ops

Infrastructure-as-code and GitOps repository for a Talos Linux Kubernetes cluster. Kubernetes manifests live in `kubernetes/`, Talos cluster configuration in `talos/`, Ansible provisioning in `ansible/`, and repository validation helpers in `scripts/`. Planning and deeper repository documentation belong in `docs/`.

## Policy

- Do not commit decrypted secret material; keep sensitive values encrypted according to `.sops.yaml`.

## Where things are

- Kubernetes GitOps source: `kubernetes/`
- Talos cluster configuration: `talos/`
- Ansible provisioning: `ansible/`
- Validation and audit scripts: `scripts/`
- CI validation: `.github/workflows/gitops-validate.yaml`
- Local Git hooks: `.githooks/`
- SOPS encryption rules: `.sops.yaml`

## Running and verifying

- Enable the repository hooks with `git config core.hooksPath .githooks`.
- Validate all Kustomize references and render all Kustomizations with `bash scripts/validate-kustomization-paths.sh --all`.
- Run Flux dry-run validation with `bash scripts/flux-preflight.sh`; use `--include-archive` only when archived manifests are intentionally in scope.
- Before changing Talos configuration, regenerate with `cd talos && talhelper genconfig`, then validate the generated node configurations with `talosctl validate`.
- After changing Talos configuration, compare the generated configuration with the deployed machine configuration before applying it.
- CI runs the Kustomize validation and Flux preflight checks for changes under `kubernetes/`, `scripts/`, `.githooks/`, and this workflow.

## Conventions that differ from defaults

- Treat `kubernetes/` as the declarative source of truth; validate and render manifests instead of applying unrendered ad-hoc changes.
- Regenerate the Flux dependency graph through the pre-commit hook or `python3 scripts/flux-graph.py --update-readme`; do not hand-edit the generated graph in `README.md`.
- Do not regenerate Talos cluster secrets with `talhelper gensecret` for the existing cluster; use it only for a deliberate full rebuild from scratch.

<!-- /bmad:context -->
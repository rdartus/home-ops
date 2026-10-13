- source_spec: `/home/jeank/home-ops/_bmad-output/implementation-artifacts/spec-dawarich-gitops-integration.md`
  summary: Add CI validation that renders bjw-s HelmRelease values and asserts generated workload and Service contracts.
  evidence: Existing repository checks validate Kustomize and Flux objects but do not render remote Helm charts; this requires a Helm repository/chart rendering step.

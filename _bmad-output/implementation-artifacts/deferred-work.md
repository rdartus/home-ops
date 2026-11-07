- source_spec: `/home/jeank/home-ops/_bmad-output/implementation-artifacts/spec-dawarich-gitops-integration.md`
  summary: Add CI validation that renders bjw-s HelmRelease values and asserts generated workload and Service contracts.
  evidence: Existing repository checks validate Kustomize and Flux objects but do not render remote Helm charts; this requires a Helm repository/chart rendering step.
- source_spec: `/home/jeank/home-ops/_bmad-output/implementation-artifacts/spec-test-pg-restore-gitsync.md`
  summary: Establish verified SSH host keys for all Git LFS synchronization jobs.
  evidence: The isolated test preserves the existing ssh-known-hosts=false configuration; deciding and distributing known_hosts data requires a repository-wide change.
- source_spec: `/home/jeank/home-ops/_bmad-output/implementation-artifacts/spec-test-pg-restore-gitsync.md`
  summary: Reconcile the pre-existing pg-dump-sync CronJob schedule changes.
  evidence: The reviewer finding concerns dirty-tree changes outside the isolated restore test and is not caused by this story.
- source_spec: `/home/jeank/home-ops/_bmad-output/implementation-artifacts/spec-test-pg-restore-gitsync.md`
  summary: Add live-cluster runtime coverage for pg-restore-test success and failure scenarios.
  evidence: The scenarios require the live cluster, Vault-backed SSH secret, Git LFS repository, and real dump data; static repository validation cannot execute them.
- source_spec: `/home/jeank/home-ops/_bmad-output/implementation-artifacts/spec-test-pg-restore-gitsync.md`
  summary: Automate verification of the production pg-restore git-sync image upgrade.
  evidence: The requested test is intentionally opt-in to avoid production mutation, so runtime proof must be run manually against an operator-controlled cluster.

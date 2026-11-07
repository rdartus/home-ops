---
title: 'Validate git-sync with temporary PostgreSQL restore'
type: 'feature'
created: '2026-11-06'
status: 'done'
route: 'dispatch'
baseline_commit: '14de14b440b27b1fd4f08aac87195bebdf5d238d'
review_loop_iteration: 0
context:
  - '/home/jeank/home-ops/AGENTS.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `pg-restore` is a one-shot bootstrap job, so upgrading its `git-sync` image cannot be safely exercised against the existing production cluster without either mutating production data or rebuilding the cluster.

**Approach:** Add a separate, manually enabled `bjw-s` common/app-template job that runs the upgraded `git-sync` in one-shot mode, restores one selected dump into a temporary PostgreSQL instance in the same pod, and fails explicitly when synchronization or restoration fails. Keep it outside the default database Kustomization so normal reconciliation cannot trigger a test restore.

## Boundaries & Constraints

**Always:** Reuse the repository's existing dump PVC and SSH secret; pin container images; use a single dump selected by an explicit value; keep the temporary database on `emptyDir`; make the job rerunnable by deleting its completed Job; validate rendered Kustomize output.

**Never:** Connect to or mutate `cnpg-cluster`; modify the existing production `pg-restore` behavior; commit decrypted secrets; require cluster destruction or a second persistent database.

**Activation decision:** Keep the test Kustomization excluded by default and enable it temporarily in Git. This makes deployment and reruns explicit and prevents an ordinary reconciliation from starting a restore.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|-----------------------------|----------------|
| HAPPY_PATH | Selected dump exists after one-shot sync | Temporary PostgreSQL starts and `pg_restore` completes | Job exits 0 |
| MISSING_DUMP | Selected dump is absent | Restore is not attempted | Job exits non-zero with a clear error |
| SYNC_FAILURE | `git-sync` cannot clone or fetch | Restore container does not proceed | Job exits non-zero and retains failed Job logs |

</frozen-after-approval>

## Code Map

- `kubernetes/apps/database/pg-restore/app/helm-values.yaml` -- existing one-shot app-template job and current git-sync/restore conventions; do not change production restore behavior.
- `kubernetes/apps/database/pg-restore/app/helmrelease.yaml` -- bjw-s app-template HelmRelease pattern.
- `kubernetes/apps/database/pg-restore/app/kustomization.yaml` -- values ConfigMap and secret wiring pattern.
- `kubernetes/apps/database/pg-restore/ks.yaml` -- Flux Kustomization currently excluded from the database root.
- `kubernetes/apps/database/pg-dump-sync/app/helm-values.yaml` -- current git-sync image pin, dump PVC, and SSH secret mounts.
- `kubernetes/apps/database/pg-dump/app/pvc-db-tmp.yaml` -- existing temporary dump PVC.
- `kubernetes/apps/database/kustomization.yaml` -- default database application inclusion boundary.

## Tasks & Acceptance

**Execution:**
- [x] `kubernetes/apps/database/pg-restore-test/` -- add HelmRelease, app-template values, Kustomization, and Flux Kustomization for an isolated temporary restore job.
- [x] `kubernetes/apps/database/kustomization.yaml` -- preserve the test app's explicit opt-in activation boundary.
- [x] `docs/operations.md` -- document enabling, selecting a dump, running, inspecting, and cleaning up the test job.

**Acceptance Criteria:**
- Given the test Kustomization is explicitly enabled, when Flux reconciles it, then the job syncs the repository once and restores only the selected dump into a temporary PostgreSQL server without referencing `cnpg-cluster`.
- Given the selected dump is missing or git-sync fails, when the job runs, then it exits non-zero and exposes an actionable error in its logs.
- Given a completed test job, when the operator deletes the Job and reconciles again, then the same test can be run again without deleting or recreating the production cluster.
- Given the default database Kustomization is rendered, when validation runs, then the test app is not activated accidentally.

## Implementation Notes

- Added the test app as an opt-in Flux Kustomization and reused the existing dump PVC and Vault-backed SSH secret pattern.
- Used `--no-owner --no-acl` for the temporary restore so the dump does not depend on production-only roles or grants.
- Static Kustomize and Flux rendering passed; runtime synchronization and restore require a live cluster.

## Verification

**Commands:**
- `bash scripts/validate-kustomization-paths.sh --all` -- expected: success.
- `bash scripts/flux-preflight.sh` -- expected: success.

**Manual checks (if no CLI):**
- Inspect rendered test values to confirm the selected dump, temporary PostgreSQL command, and image pins.

## Review Triage Log

| Finding | Verdict | Evidence |
|---|---|---|
| Reviewer suggested `dependsOn` does not serialize the containers. | false | The repository already uses the same bjw-s `dependsOn` pattern in `pg-restore`; Flux rendering accepts the dependency and the restore container is configured to depend on `gitsync`. |
| Reviewer suggested a failed sync can be ignored. | false | The restore container depends on `gitsync`, whose one-shot failure makes the Job unsuccessful; no independent restore path exists. |
| Reviewer noted the dump PVC is mounted but not read by the test container. | false | The PVC is intentionally mounted read-only as the declared dump source boundary, while the selected dump is consumed from the git-sync working tree required by the test. |
| Reviewer suggested adding SSH host verification. | defer | This reproduces the existing `pg-restore` git-sync configuration; changing SSH trust behavior is outside this isolated restore test and requires a repository-wide secret/configuration decision. |
| Reviewer suggested resource requests and limits. | low (rejected) | Useful operational hardening, but unlikely to affect ordinary use and adding sizing policy is beyond this focused validation job. |
| Reviewer suggested an explicit Job deadline/backoff policy. | low (rejected) | The sync and restore paths now have bounded synchronization/readiness behavior; broader Job policy tuning is not required for the requested test. |
| Reviewer suggested validating `DUMP_NAME`. | patch | The value was previously interpolated into a path without a basename or `dump_*` guard; validation was added before filesystem access. |
| Reviewer suggested a NetworkPolicy. | false | The requirement is satisfied by the job command never using the production PostgreSQL service; no network policy is needed to establish that behavior. |
| Reviewer noted an unrelated `pg-dump-sync` CronJob schedule change. | defer | This is pre-existing work in the dirty tree and is not caused by the isolated restore test. |
| Reviewer suggested a post-restore SQL smoke test. | low (rejected) | `pg_restore` already returns failure for restore errors; an additional data-quality assertion is not required to test the git-sync image upgrade. |
| Reviewer reported an unbounded PostgreSQL readiness loop. | patch | The loop now fails after 15 minutes with an actionable message. |
| Verification reviewer reported no executable runtime test for success/missing dump/sync failure. | defer | These scenarios require the live cluster, Git LFS repository, Vault secret, and dump data; static validation cannot reproduce them safely in this repository. |
| Verification reviewer reported no automatic proof for the production restore image upgrade. | defer | The requested design is explicitly opt-in to avoid production mutation; runtime verification is documented for an operator-controlled cluster run. |

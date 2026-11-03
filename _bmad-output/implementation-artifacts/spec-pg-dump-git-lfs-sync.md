---
title: 'Publish PostgreSQL dumps to Git LFS'
type: 'feature'
created: '2026-11-03'
status: 'done'
route: 'dispatch'
baseline_commit: '4f7c19b9cf02b3a4d22c9ff34733592ce711719a'
review_loop_iteration: 0
context:
  - '/home/jeank/home-ops/kubernetes/apps/database/pg-dump-sync/app/helm-values.yaml'
  - '/home/jeank/home-ops/kubernetes/apps/database/pg-restore/app/helm-values.yaml'
  - '/home/jeank/home-ops/kubernetes/apps/database/pg-restore/app/ssh-secret.yaml'
  - '/home/jeank/home-ops/kubernetes/apps/database/pg-restore/app/ssh-auth.yaml'
  - '/home/jeank/home-ops/docs/operations.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The current NAS export provides an external copy of PostgreSQL dumps, but a cluster reconstruction should be able to restore from `git@gitlab.com:k3s-pi1/dump-k3s.git` through Git LFS instead of depending on the NAS. The repository must keep the current dumps and one month-end fallback.

**Approach:** Extend the existing `pg-dump-sync` flow with a daily Git LFS push using the existing Vault-projected SSH key. Push the current dump set to `main`; on the first run of each month, rotate the last already-published set into `previous` before publishing the new current set. Keep `pg-restore` aligned with the existing Git LFS `git-sync` configuration so it consumes `main` by default.

**Decisions:** Use branches `main` and `previous`. Push once per day. On day 1 of each month, force-update `previous` from the last published `main` state before committing the new dumps to `main`. Use the existing `ssh-secret` and the pinned `ghcr.io/rdartus/git-sync` image with Git LFS support. Do not store private keys or credentials in Git.

## Boundaries & Constraints

**Always:** Preserve the existing NAS export; make Git operations fail the Job visibly; use atomic repository updates (commit only complete dump files); keep `pg-restore` reading `main` through Git LFS; avoid logging key material or repository credentials.

**Never:** Push plaintext secrets; delete the NAS copy after a successful Git push; overwrite `previous` after a failed rotation; run a Git push from the database dump container; change unrelated restore databases.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Daily publish | Complete dumps exist and GitLab SSH/LFS access works | `main` contains the current dump set and the Job succeeds | A failed clone, LFS upload, or push fails the Job and leaves NAS/local dumps intact |
| Monthly rotation | First daily run of a calendar month and `main` has a prior published state | `previous` is replaced with the last `main` state before today's dumps are committed to `main` | Do not push today's `main` or delete/alter `previous` if rotation fails |
| No changes | Dumps are identical to the already published state | No empty commit is created; Job succeeds | Git status is checked explicitly |
| Restore reconstruction | `pg-restore` runs with GitLab reachable | `git-sync` checks out `main`, downloads LFS objects, and restore reads `/data/dump-k3s` | Missing key, branch, or LFS object fails before restore rather than restoring an incomplete set |

</frozen-after-approval>

## Code Map

- `kubernetes/apps/database/pg-dump-sync/app/helm-values.yaml` -- existing hourly NAS sync; add a separate daily Git LFS publisher container/workload without removing NAS export.
- `kubernetes/apps/database/pg-restore/app/helm-values.yaml` -- user-provided local Git LFS restore configuration; preserve its intent and make only correctness/wiring changes needed by the publisher.
- `kubernetes/apps/database/pg-restore/app/ssh-secret.yaml` -- VaultStaticSecret producing `ssh-secret`; reuse it for GitLab authentication.
- `kubernetes/apps/database/pg-restore/app/ssh-auth.yaml` -- Vault authentication for the SSH secret; do not add plaintext credentials.
- `kubernetes/apps/database/pg-restore/app/kustomization.yaml` -- existing restore resource wiring.
- `docs/operations.md` -- document Git LFS publication, branch rotation, and reconstruction checks.

## Tasks & Acceptance

**Execution:**
- [x] Add a daily Git LFS publisher scheduled after the daily dump, using the existing SSH secret and pinned Git LFS-capable image.
- [x] Publish complete dump files to `main`, rotate the prior `main` state to `previous` on day 1, and fail safely on clone/LFS/push errors.
- [x] Preserve and validate the user's `pg-restore` Git LFS configuration for `main`.
- [x] Document operational verification, branch semantics, and restore behavior.
- [x] Render and validate all affected Kustomizations and run Flux preflight.

**Acceptance Criteria:**
- Given a complete daily dump set, when the publisher runs, then Git LFS contains the set on `main` and the Job succeeds.
- Given the first publisher run of a month, when rotation succeeds, then `previous` contains the last published `main` state and `main` contains the new set.
- Given GitLab or Git LFS is unavailable, when the publisher runs, then the Job fails and the NAS/local dump copies and `previous` branch remain unchanged.
- Given a reconstruction, when `pg-restore` starts, then it downloads `main` through Git LFS before running `pg_restore`.

## Implementation Notes

- Added a daily Git LFS publisher CronJob at 00:30, after the 00:10 dump run.
- The publisher uses the Vault-projected `ssh-secret`, known-host verification, the pinned Git LFS image, and a non-secret Git identity.
- The publisher updates `main` only after complete dump files are copied, and rotates the prior `main` commit to `previous` on day 1.
- Preserved the existing NAS export and the user's Git LFS restore configuration, enabling known-host verification for reconstruction.
- Live GitLab SSH/LFS push and restore tests remain pending because they require the cluster and repository credentials.

## Verification

**Commands:**
- `bash scripts/validate-kustomization-paths.sh --all` -- expected: all Kustomize paths and rendered manifests validate.
- `bash scripts/flux-preflight.sh` -- expected: Flux dry-run validation succeeds.

## Review Triage Log

| Finding | Verdict | Evidence |
|---|---|---|
| Publisher needed an explicit Git author identity | fixed | The publisher configures a non-secret local Git name and email before committing. |
| SSH host verification was disabled | fixed | Publisher and restore now use the Vault-projected `known_hosts`; the publisher enables strict verification. |
| Live GitLab/LFS behavior cannot be tested locally | deferred | The repository has no usable credentials or cluster runtime in this session; validate with the documented `git ls-remote`, `git lfs fsck`, and Kubernetes Job checks. |

---
title: 'Export PostgreSQL dumps to NAS'
type: 'feature'
created: '2026-11-03'
status: 'done'
route: 'dispatch'
baseline_commit: 'e97e696684fb1521c3caeea7dfc199a45fcea0cb'
review_loop_iteration: 0
context:
  - '/home/jeank/home-ops/kubernetes/apps/database/pg-dump'
  - '/home/jeank/home-ops/kubernetes/apps/database/pg-dump-sync'
  - '/home/jeank/home-ops/kubernetes/apps/kube-system/csi-driver-smb'
  - '/home/jeank/home-ops/docs/operations.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** PostgreSQL dumps are produced on a Longhorn PVC inside the Kubernetes cluster, so a cluster failure can make both the databases and their backups unavailable. The dumps need to be copied regularly to the user's NAS.

**Approach:** Extend the existing `pg-dump` and `pg-dump-sync` flow so dumps are written to a NAS-backed persistent volume, while keeping credentials in the repository's existing Vault-managed secret flow and preserving the current restore path.

**Decisions:** Use the existing CSI SMB integration. Mount the dedicated NAS subdirectory `//nascobar.dartus.fr/jeantasse/db-backups`. Automatically retain dumps for 30 days, then prune them. Protect the dumps with the SMB share's access controls; no application-level encryption is added in this iteration.

## Boundaries & Constraints

**Always:** Keep the Kubernetes manifests declarative; retain the existing dump schedule and database list unless required for correctness; use a NAS-mounted PVC rather than embedding credentials in a container command; make sync failures visible through Kubernetes Job/CronJob status; document restore and operational verification.

**Never:** Commit decrypted NAS credentials; delete the local dump before a successful NAS copy; expose PostgreSQL or the NAS publicly; replace the existing CNPG cluster or change unrelated application storage.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Successful export | A completed dump exists and the NAS volume is writable | The dump is copied to the NAS with a deterministic path/name and the job succeeds | N/A |
| NAS unavailable | The NAS share cannot be mounted or written | The local dump remains available and the sync job fails visibly | Kubernetes retries according to the CronJob policy and reports failure |
| Partial copy | A copy is interrupted | No partial file is treated as the current backup | Copy to a temporary name and rename atomically, or use an equivalent safe-copy mechanism |
| Restore | An operator selects a NAS dump | The existing restore workflow can consume the selected dump after it is made available in-cluster | Document the copy-back and validation steps |

</frozen-after-approval>

## Code Map

- `kubernetes/apps/database/pg-dump/app/helm-values.yaml` -- hourly PostgreSQL dump CronJob, database list, and local `pvc-db-tmp` mount; reuse the dump schedule and command structure.
- `kubernetes/apps/database/pg-dump/app/pvc-db-tmp.yaml` -- Longhorn RWX claim currently holding dumps.
- `kubernetes/apps/database/pg-dump-sync/app/helm-values.yaml` -- sync workload currently mounts `pvc-db-tmp` but is an idle deployment; convert or extend it for scheduled NAS export.
- `kubernetes/apps/database/pg-dump-sync/app/kustomization.yaml` -- sync Helm values wiring; add only tightly coupled PVC/config resources here.
- `kubernetes/apps/kube-system/csi-driver-smb/ressources/all-storageClass.yaml` -- existing NAS CSI SMB pattern and Vault secret references.
- `kubernetes/apps/default/filebrowser/app/smb-secret.yaml` -- VaultStaticSecret pattern for NAS credentials; reuse the secret flow without copying plaintext values.
- `docs/operations.md` -- operational database backup/restore documentation to update with NAS export and restore verification.

## Tasks & Acceptance

**Execution:**
- [x] Add a NAS-backed claim and wire it into the sync workload using the selected repository storage pattern.
- [x] Make `pg-dump-sync` run after dumps are produced, copy safely, and report failures without removing the source dump.
- [x] Add retention/protection behavior selected in the open questions.
- [x] Document operational verification and restore from the NAS.
- [x] Render and validate all affected Kustomizations and run the repository's Flux preflight checks.

**Acceptance Criteria:**
- Given the dump CronJob has produced a dump, when the sync schedule runs, then the dump is present on the NAS and the sync workload reports success.
- Given the NAS is unavailable, when the sync schedule runs, then it reports failure and the local dump remains available for retry or recovery.
- Given an operator follows the documented restore procedure, when a NAS dump is selected, then it can be brought into the existing restore workflow without accessing plaintext credentials from Git.

## Implementation Notes

- Added a dedicated CSI SMB StorageClass and RWX PVC for `//nascobar.dartus.fr/jeantasse/db-backups`.
- Converted `pg-dump-sync` to an hourly CronJob at minute 20 with atomic NAS copies, stale temporary-file cleanup, and 30-day retention.
- Updated `pg-dump` to publish completed dumps atomically and fail the CronJob when a database dump fails, preventing the sync job from reading a partially written file.
- NAS mount, copy, failure, and restore behavior still require live-cluster verification.

## Verification

**Commands:**
- `bash scripts/validate-kustomization-paths.sh --all` -- expected: all Kustomize paths and rendered manifests validate.
- `bash scripts/flux-preflight.sh` -- expected: Flux dry-run validation succeeds.

## Review Triage Log

| Finding | Verdict | Evidence |
|---|---|---|
| Sync could read a dump while `pg_dump` is still writing it | fixed | `pg-dump` now writes to `/db/.dump_*.tmp` and renames only after `pg_dump` succeeds. |
| Sync recopies unchanged files | low | The NAS target is small and the existing flow has no manifest/checksum index; repeated copies remain correct but can be optimized separately. |
| Atomic rename does not checksum-verify content | low | The copy is protected from partial destination visibility; end-to-end corruption detection is outside the selected first iteration. |
| A 30-second sync deadline is too short | fixed | The sync starting deadline is now 900 seconds. |
| Restore documentation lacks target-specific and quiescing details | low | The procedure identifies `pg-restore`, `pg_restore --list`, logs, and application checks; target-specific runbooks remain operator-dependent. |
| No automated runtime test covers NAS mount/copy behavior | accepted | Repository validation is declarative; live NAS and cluster behavior must be verified with the documented `kubectl` checks after deployment. |
| A failed NAS mount may leave a Job pending rather than failed | accepted | CSI mount failures are surfaced through Pod events and PVC state; Kubernetes cannot execute the copy container until the mount succeeds. |

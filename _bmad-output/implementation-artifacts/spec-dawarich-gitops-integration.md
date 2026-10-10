---
title: 'Integrate Dawarich into the default GitOps applications'
type: 'feature'
created: '2026-10-10'
status: 'done'
route: 'dispatch'
baseline_commit: '0813d2486408a09b8dabebceeebf4a8671f5e116'
review_loop_iteration: 0
context:
  - '/home/jeank/home-ops/kubernetes/apps/default/trek'
  - '/home/jeank/home-ops/kubernetes/apps/default/immich'
  - '/home/jeank/home-ops/kubernetes/apps/database/cnpg'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Dawarich is currently defined as a Docker Compose stack, but this cluster is managed through Flux and the bjw-s app-template. The application needs a Kubernetes-native deployment with durable storage, PostgreSQL/PostGIS, Redis-compatible queueing, background processing, secrets, and HTTPS access.

**Approach:** Add a self-contained `kubernetes/apps/default/dawarich` Kustomization using bjw-s app-template for the web, Sidekiq, Redis, and PostGIS workloads. Store credentials and the Rails secret in VaultStaticSecrets, expose only the web service through the existing Traefik ingress, and use Longhorn PVCs for all stateful data. Keep Immich's TensorChord-backed PostgreSQL database and shared Valkey deployment unchanged.

## Boundaries & Constraints

**Always:** Follow the Trek/Immich Flux, Vault, ingress, naming, and app-template conventions; pin images where repository conventions support it; keep secrets out of Git; provide health probes and resource requests/limits; use a PostGIS-capable database image; validate rendered Kustomize output and Flux preflight.

**Never:** Do not reuse Immich's database or mutate the existing CNPG cluster; do not expose PostgreSQL or Redis externally; do not commit plaintext credentials; do not add OIDC unless it is already supported by the Dawarich image and configured separately.

**Decision:** Publish Dawarich at `dawarich.dartus.fr`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| HAPPY_PATH | Flux reconciles the Dawarich Kustomization and Vault secrets exist | PostGIS, Redis, web, and Sidekiq become ready; HTTPS routes to the web service | Readiness gates prevent dependent workloads from serving prematurely |
| DATABASE_UNAVAILABLE | PostGIS is unavailable during startup or migration | Web and Sidekiq remain non-ready and retry through their entrypoints | Probes report failure; no external service is advertised as healthy |
| PVC_RESTART | A pod restarts with existing Longhorn volumes | Application data, imports, public assets, and database data persist | Workload must mount each data path consistently |

</frozen-after-approval>

## Code Map

- `kubernetes/apps/default/trek/ks.yaml` and `kubernetes/apps/default/trek/app/` -- reference Flux Kustomization, Vault authentication, PVCs, app-template values, and Traefik ingress.
- `kubernetes/apps/default/immich/app/helm-values.yaml` -- reference database/Redis environment wiring and existing bjw-s value structure.
- `kubernetes/apps/default/valkey/` -- existing shared Redis-compatible service; it remains unchanged because Dawarich's Compose contract and persistence should be isolated.
- `kubernetes/apps/database/cnpg/` -- existing Immich/TensorChord PostgreSQL cluster; explicitly not reused because Dawarich requires PostGIS.
- `scripts/validate-kustomization-paths.sh` and `scripts/flux-preflight.sh` -- repository validation commands.

## Tasks & Acceptance

**Execution:**
- [x] Add `kubernetes/apps/default/dawarich/ks.yaml` and app Kustomization -- register the Flux-managed application with dependencies on Vault and Traefik.
- [x] Add Dawarich VaultAuth/VaultStaticSecret resources -- provide database, Redis, Rails, and host configuration without plaintext secrets.
- [x] Add app-template HelmRelease and values -- deploy PostGIS, Redis, web, and Sidekiq with probes, dependencies, resource controls, PVC mounts, and HTTPS ingress.
- [x] Add Longhorn PVC definitions -- persist database, shared, public, watched-import, and application storage paths.
- [x] Validate the resulting manifests -- catch path, schema, rendering, and Flux preflight errors before handoff.

**Acceptance Criteria:**
- Given the Dawarich directory is reconciled, when Flux renders it, then all referenced resources resolve and the Kustomization is healthy.
- Given Vault provides the configured secrets, when the workloads start, then web and Sidekiq use the same PostGIS and Redis endpoints and no credentials are embedded in Git.
- Given the web pod is healthy, when a request reaches the configured HTTPS hostname, then Traefik routes it to port 3000 with a cert-manager TLS certificate.
- Given any application or database pod restarts, when it remounts its PVCs, then database data, public files, watched imports, and storage remain available.

## Implementation Notes

The deployment is self-contained under `kubernetes/apps/default/dawarich`: PostGIS and Redis
are stateful app-template controllers, while the web and Sidekiq controllers share the
application PVCs. Vault supplies all credentials and host-specific secret material through
`dawarich-config`; no secret values are stored in Git.

## Verification

**Commands:**
- `bash scripts/validate-kustomization-paths.sh --all` -- expected: success.
- `bash scripts/flux-preflight.sh` -- expected: success.
- `kubectl kustomize kubernetes/apps/default/dawarich/app` -- expected: success.

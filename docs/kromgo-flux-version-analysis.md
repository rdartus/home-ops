# Kromgo Flux Version Incident Analysis

Date: 2026-10-02

## Executive summary

Kromgo is not failing on the Flux PromQL expression. The live Kromgo pod cannot resolve
its configured Prometheus hostname:

```text
dial tcp: lookup kube-prometheus-stack-kube-prometheus.observability.svc.cluster.local
on 10.96.0.10:53: no such host
```

The live Prometheus Service is named
`kube-prometheus-stack-prometheus`, not `kube-prometheus-stack-kube-prometheus`.
The requested fix is therefore an internal observability-client configuration change,
not a change to `flux_instance_info` or to the ServiceMonitor selector. Grafana had
the same stale hostname and is corrected in the same change to avoid leaving a second
broken Prometheus client after the release rename.

## Evidence collected from the live cluster

### Flux is healthy

```text
flux check: all checks passed
flux distribution: flux-v2.7.5
FluxInstance/flux: READY=True
FluxInstance revision: v2.7.5@sha256:27216199c53fad6f5d1725b1bbdaefd4a665640c804ce74105278d0d907923d8
```

### Prometheus services

The live services include:

```text
kube-prometheus-stack-prometheus   10.104.137.95   9090/TCP,8080/TCP
prometheus-operated                headless         9090/TCP
```

There is no service named:

```text
kube-prometheus-stack-kube-prometheus
```

### Kromgo configuration currently rendered in the pod

```yaml
PROMETHEUS_URL: http://kube-prometheus-stack-kube-prometheus.observability.svc.cluster.local:9090
```

This value is sourced from
`kubernetes/apps/observability/kromgo/app/helm-values.yaml`.

### Kromgo logs

The live pod logs contain:

```text
error executing metric query
Post "http://kube-prometheus-stack-kube-prometheus.observability.svc.cluster.local:9090/api/v1/query":
dial tcp: lookup kube-prometheus-stack-kube-prometheus.observability.svc.cluster.local
on 10.96.0.10:53: no such host
```

This explains the current public response:

```http
GET /flux_version
HTTP/2 500

{"schemaVersion":1,"label":"flux_version","message":"Query Error","isError":true}
```

This is different from the earlier `No Data` state. `No Data` meant that Kromgo
could reach Prometheus and received an empty vector. The current `Query Error`
occurs before Prometheus can execute the query because DNS resolution fails.

## Request chain

```text
Client
  -> GET https://kromgo.dartus.fr/flux_version
  -> Kromgo main server on port 80
  -> Prometheus HTTP API /api/v1/query
  -> configured DNS name (currently invalid)
  -> DNS failure
  -> Kromgo HTTP 500 Query Error
```

Once corrected:

```text
Kromgo
  -> http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090
  -> POST /api/v1/query
  -> label_replace(flux_instance_info, ...)
  -> vector containing FluxInstance/flux
  -> extract label revision
  -> JSON or badge response
```

## Flux metric path

The live `ServiceMonitor/flux-operator` exists in namespace `flux-system` and
selects the Flux Operator Service on port `8080`, path `/metrics`, every 30 seconds.
Its label is:

```yaml
release: kube-prometheus-stack
```

The live Prometheus custom resource selects ServiceMonitors with:

```yaml
serviceMonitorSelector:
  matchLabels:
    release: kube-prometheus-stack
```

Therefore the ServiceMonitor selection is consistent. No selector correction is
needed for the current incident.

Kromgo's configured Flux query remains:

```promql
label_replace(
  flux_instance_info,
  "revision",
  "$1",
  "revision",
  "v(.+)@sha256:.+"
)
```

The query is expected to return a vector whose `revision` label is transformed
from `v2.7.5@sha256:...` to `2.7.5`.

The exact query was executed against the live Prometheus API during this
investigation and returned one ready Flux instance:

```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "name": "flux",
          "exported_namespace": "flux-system",
          "ready": "True",
          "revision": "2.7.5"
        },
        "value": ["1790947310.624", "1"]
      }
    ]
  }
}
```

This proves that the Flux metric and PromQL expression are healthy independently
of Kromgo. The remaining failure is exclusively the stale Kromgo Prometheus URL.

## Corrective change

Change the Prometheus URL used by Kromgo and Grafana:

```diff
- PROMETHEUS_URL: http://kube-prometheus-stack-kube-prometheus.observability.svc.cluster.local:9090
+ PROMETHEUS_URL: http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090
```

The equivalent Grafana datasource value is changed from the same stale hostname to
`http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090`.

The URL is deliberately kept on the chart-created Prometheus Service. The
`prometheus-operated` Service is a possible fallback, but using the named release
Service keeps the dependency explicit and matches the live service inventory.

## Verification

After Flux reconciliation and rollout completion:

```bash
flux reconcile kustomization kromgo --with-source
flux reconcile kustomization grafana --with-source
kubectl -n observability wait --for=condition=ready helmrelease/kromgo --timeout=5m
kubectl -n observability wait --for=condition=ready helmrelease/grafana --timeout=5m
kubectl -n observability rollout status deployment/kromgo --timeout=5m
kubectl -n observability logs deploy/kromgo -c app --since=5m
curl -fsS 'https://kromgo.dartus.fr/flux_version?format=raw'
curl -fsS 'https://kromgo.dartus.fr/flux_version'
```

The verification passes only when the Kromgo logs contain no DNS error, the raw
response is a non-empty JSON array, and the endpoint response has `isError` absent
with `label: "Flux"` and a non-empty `message`.

Expected raw response shape:

```json
[
  {
    "metric": {
      "revision": "2.7.5"
    },
    "value": ["<timestamp>", "1"]
  }
]
```

Expected endpoint response shape:

```json
{
  "schemaVersion": 1,
  "label": "Flux",
  "message": "2.7.5"
}
```

## Validation performed before deployment

The corrected Kustomize overlays rendered successfully with `kubectl kustomize`,
and `git diff --check` passed. The repository helper scripts could not run to
completion because the local environment does not have `yq` installed:

```text
[kustomization-check] Missing required command: yq
[flux-preflight] Missing required command: yq
```

The live Kromgo endpoint was intentionally not expected to recover before the
commit is pushed and reconciled by Flux. Until then, its pod still uses the
old ConfigMap and will continue to return `Query Error`.

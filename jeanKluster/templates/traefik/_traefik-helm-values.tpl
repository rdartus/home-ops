# Default values for Traefik
# This is a YAML-formatted file.
# Declare variables to be passed into templates
{{- define "helmValues.traefik" }}

image:  # @schema additionalProperties: false
  # -- Traefik image host registry
  registry: docker.io
  # -- Traefik image repository
  repository: traefik
  # -- defaults to appVersion
  tag:  # @schema type:[string, null]
  # -- Traefik image pull policy
  pullPolicy: IfNotPresent

# -- Add additional label to all resources
commonLabels: {}

deployment:
  # -- Enable deployment
  enabled: true
  # -- Deployment or DaemonSet
  kind: Deployment
  # -- Number of pods of the deployment (only applies when kind == Deployment)
  replicas: 1
  # -- Number of old history to retain to allow rollback (If not set, default Kubernetes value is set to 10)
  revisionHistoryLimit:  # @schema type:[integer, null];minimum:0
  # -- Amount of time (in seconds) before Kubernetes will send the SIGKILL signal if Traefik does not shut down
  terminationGracePeriodSeconds: 60
  # -- The minimum number of seconds Traefik needs to be up and running before the DaemonSet/Deployment controller considers it available
  minReadySeconds: 0
  ## -- Override the liveness/readiness port. This is useful to integrate traefik
  ## with an external Load Balancer that performs healthchecks.
  ## Default: ports.traefik.port
  healthchecksPort:  # @schema type:[integer, null];minimum:0
  ## -- Override the liveness/readiness host. Useful for getting ping to respond on non-default entryPoint.
  ## Default: ports.traefik.hostIP if set, otherwise Pod IP
  healthchecksHost: ""
  ## -- Override the liveness/readiness scheme. Useful for getting ping to
  ## respond on websecure entryPoint.
  healthchecksScheme:   # @schema enum:[HTTP, HTTPS, null]; type:[string, null]; default: HTTP
  ## -- Override the readiness path.
  ## Default: /ping
  readinessPath: ""
  # -- Override the liveness path.
  # Default: /ping
  livenessPath: ""
  # -- Additional deployment annotations (e.g. for jaeger-operator sidecar injection)
  annotations: {}
  # -- Additional deployment labels (e.g. for filtering deployment by custom labels)
  labels: {}
  # -- Additional pod annotations (e.g. for mesh injection or prometheus scraping)
  # It supports templating. One can set it with values like traefik/name: { template "traefik.name" . }
  podAnnotations: {}
  # -- Additional Pod labels (e.g. for filtering Pod by custom labels)
  podLabels: {}
  # -- Additional containers (e.g. for metric offloading sidecars)
  additionalContainers: []
  # https://docs.datadoghq.com/developers/dogstatsd/unix_socket/?tab=host
  # - name: socat-proxy
  #   image: alpine/socat:1.0.5
  #   args: ["-s", "-u", "udp-recv:8125", "unix-sendto:/socket/socket"]
  #   volumeMounts:
  #     - name: dsdsocket
  #       mountPath: /socket
  # -- Additional volumes available for use with initContainers and additionalContainers
  additionalVolumes: []
  # - name: dsdsocket
  #   hostPath:
  #     path: /var/run/statsd-exporter
  # -- Additional initContainers (e.g. for setting file permission as shown below)
  initContainers: []
  # The "volume-permissions" init container is required if you run into permission issues.
  # Related issue: https://github.com/traefik/traefik-helm-chart/issues/396
  # - name: volume-permissions
  #   image: busybox:latest
  #   command: ["sh", "-c", "touch /data/acme.json; chmod -v 600 /data/acme.json"]
  #   volumeMounts:
  #     - name: data
  #       mountPath: /data
  # -- Use process namespace sharing
  shareProcessNamespace: false
  # -- Custom pod DNS policy. Apply if `hostNetwork: true`
  dnsPolicy: ""
  # -- Custom pod [DNS config](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.30/#poddnsconfig-v1-core)
  dnsConfig: {}
  # -- Custom [host aliases](https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/)
  hostAliases: []
  # -- Pull secret for fetching traefik container image
  imagePullSecrets: []
  # -- Pod lifecycle actions
  lifecycle: {}
  # preStop:
  #   exec:
  #     command: ["/bin/sh", "-c", "sleep 40"]
  # postStart:
  #   httpGet:
  #     path: /ping
  #     port: 8080
  #     host: localhost
  #     scheme: HTTP
  # -- Set a runtimeClassName on pod
  runtimeClassName: ""

# -- [Pod Disruption Budget](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/pod-disruption-budget-v1/)
podDisruptionBudget:  # @schema additionalProperties: false
  enabled: false
  maxUnavailable:  # @schema type:[string, integer, null];minimum:0
  minAvailable:    # @schema type:[string, integer, null];minimum:0

# -- Create a default IngressClass for Traefik
ingressClass:  # @schema additionalProperties: false
  enabled: true
  isDefaultClass: true
  name: traefik-ingresses

core:  # @schema additionalProperties: false
  # -- Can be used to use globally v2 router syntax
  # See https://doc.traefik.io/traefik/v3.0/migration/v2-to-v3/#new-v3-syntax-notable-changes
  defaultRuleSyntax: ""

# Traefik experimental features
experimental:
  # -- Defines whether all plugins must be loaded successfully for Traefik to start
  abortOnPluginFailure: false
  # -- Enable traefik experimental plugins
  plugins: 
    bouncer:
      moduleName: "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
      version: "v1.1.13"
  # demo:
  #   moduleName: github.com/traefik/plugindemo
  #   version: v0.2.1
  kubernetesGateway:
    # -- Enable traefik experimental GatewayClass CRD
    enabled: true

gateway:
  # -- When providers.kubernetesGateway.enabled, deploy a default gateway
  enabled: true
  # -- Set a custom name to gateway
  name: ""
  # -- By default, Gateway is created in the same `Namespace` than Traefik.
  namespace: ""
  # -- Additional gateway annotations (e.g. for cert-manager.io/issuer)
  annotations: {}
  # -- [Infrastructure](https://kubernetes.io/blog/2023/11/28/gateway-api-ga/#gateway-infrastructure-labels)
  infrastructure: {}
  # -- Define listeners
  listeners:
    web:
      # -- Port is the network port. Multiple listeners may use the same port, subject to the Listener compatibility rules.
      # The port must match a port declared in ports section.
      port: 9000
      # -- Optional hostname. See [Hostname](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.Hostname)
      hostname: "*.dartus.fr"
      # Specify expected protocol on this listener. See [ProtocolType](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.ProtocolType)
      protocol: HTTP
      # -- Routes are restricted to namespace of the gateway [by default](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.FromNamespaces
      namespacePolicy:  # @schema type:[string, null]
    # websecure listener is disabled by default because certificateRefs needs to be added,
    # or you may specify TLS protocol with Passthrough mode and add "--providers.kubernetesGateway.experimentalChannel=true" in additionalArguments section.
    # websecure:
    #   # -- Port is the network port. Multiple listeners may use the same port, subject to the Listener compatibility rules.
    #   # The port must match a port declared in ports section.
    #   port: 8443
    #   # -- Optional hostname. See [Hostname](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.Hostname)
    #   hostname:
    #   # Specify expected protocol on this listener See [ProtocolType](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.ProtocolType)
    #   protocol: HTTPS
    #   # -- Routes are restricted to namespace of the gateway [by default](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.FromNamespaces)
    #   namespacePolicy:
    #   # -- Add certificates for TLS or HTTPS protocols. See [GatewayTLSConfig](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.GatewayTLSConfig)
    #   certificateRefs:
    #   # -- TLS behavior for the TLS session initiated by the client. See [TLSModeType](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.TLSModeType).
    #   mode:

gatewayClass:  # @schema additionalProperties: false
  # -- When providers.kubernetesGateway.enabled and gateway.enabled, deploy a default gatewayClass
  enabled: true
  # -- Set a custom name to GatewayClass
  name: ""
  # -- Additional gatewayClass labels (e.g. for filtering gateway objects by custom labels)
  labels: {}

ingressRoute:
  dashboard:
    # -- Create an IngressRoute for the dashboard
    enabled: false
    # -- Additional ingressRoute annotations (e.g. for kubernetes.io/ingress.class)
    annotations: {}
    # -- Additional ingressRoute labels (e.g. for filtering IngressRoute by custom labels)
    labels: {}
    # -- The router match rule used for the dashboard ingressRoute
    matchRule: PathPrefix(`/dashboard`) || PathPrefix(`/api`)
    # -- The internal service used for the dashboard ingressRoute
    services:
      - name: api@internal
        kind: TraefikService
    # -- Specify the allowed entrypoints to use for the dashboard ingress route, (e.g. traefik, web, websecure).
    # By default, it's using traefik entrypoint, which is not exposed.
    # /!\ Do not expose your dashboard without any protection over the internet /!\
    entryPoints: ["traefik"]
    # -- Additional ingressRoute middlewares (e.g. for authentication)
    middlewares: []
    # -- TLS options (e.g. secret containing certificate)
    tls: {}
  healthcheck:
    # -- Create an IngressRoute for the healthcheck probe
    enabled: false
    # -- Additional ingressRoute annotations (e.g. for kubernetes.io/ingress.class)
    annotations: {}
    # -- Additional ingressRoute labels (e.g. for filtering IngressRoute by custom labels)
    labels: {}
    # -- The router match rule used for the healthcheck ingressRoute
    matchRule: PathPrefix(`/ping`)
    # -- The internal service used for the healthcheck ingressRoute
    services:
      - name: ping@internal
        kind: TraefikService
    # -- Specify the allowed entrypoints to use for the healthcheck ingress route, (e.g. traefik, web, websecure).
    # By default, it's using traefik entrypoint, which is not exposed.
    entryPoints: ["traefik"]
    # -- Additional ingressRoute middlewares (e.g. for authentication)
    middlewares: []
    # -- TLS options (e.g. secret containing certificate)
    tls: {}

updateStrategy:  # @schema additionalProperties: false
  # -- Customize updateStrategy of Deployment or DaemonSet
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0  # @schema type:[integer, string, null]
    maxSurge: 1        # @schema type:[integer, string, null]

readinessProbe:  # @schema additionalProperties: false
  # -- The number of consecutive failures allowed before considering the probe as failed.
  failureThreshold: 1
  # -- The number of seconds to wait before starting the first probe.
  initialDelaySeconds: 2
  # -- The number of seconds to wait between consecutive probes.
  periodSeconds: 10
  # -- The minimum consecutive successes required to consider the probe successful.
  successThreshold: 1
  # -- The number of seconds to wait for a probe response before considering it as failed.
  timeoutSeconds: 2
livenessProbe:  # @schema additionalProperties: false
  # -- The number of consecutive failures allowed before considering the probe as failed.
  failureThreshold: 3
  # -- The number of seconds to wait before starting the first probe.
  initialDelaySeconds: 2
  # -- The number of seconds to wait between consecutive probes.
  periodSeconds: 10
  # -- The minimum consecutive successes required to consider the probe successful.
  successThreshold: 1
  # -- The number of seconds to wait for a probe response before considering it as failed.
  timeoutSeconds: 2

# -- Define [Startup Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes)
startupProbe: {}

providers:  # @schema additionalProperties: false
  kubernetesCRD:
    # -- Load Kubernetes IngressRoute provider
    enabled: false
    # -- Allows IngressRoute to reference resources in namespace other than theirs
    allowCrossNamespace: false
    # -- Allows to reference ExternalName services in IngressRoute
    allowExternalNameServices: false
    # -- Allows to return 503 when there is no endpoints available
    allowEmptyServices: true
    # -- When the parameter is set, only resources containing an annotation with the same value are processed. Otherwise, resources missing the annotation, having an empty value, or the value traefik are processed. It will also set required annotation on Dashboard and Healthcheck IngressRoute when enabled.
    ingressClass: ""
    # labelSelector: environment=production,method=traefik
    # -- Array of namespaces to watch. If left empty, Traefik watches all namespaces.
    namespaces: []
    # -- Defines whether to use Native Kubernetes load-balancing mode by default.
    nativeLBByDefault: false

  kubernetesIngress:
    # -- Load Kubernetes Ingress provider
    enabled: true
    # -- Allows to reference ExternalName services in Ingress
    allowExternalNameServices: false
    # -- Allows to return 503 when there is no endpoints available
    allowEmptyServices: true
    # -- When ingressClass is set, only Ingresses containing an annotation with the same value are processed. Otherwise, Ingresses missing the annotation, having an empty value, or the value traefik are processed.
    ingressClass:  # @schema type:[string, null]
    # labelSelector: environment=production,method=traefik
    # -- Array of namespaces to watch. If left empty, Traefik watches all namespaces.
    namespaces: []
    # IP used for Kubernetes Ingress endpoints
    publishedService:
      # -- Enable [publishedService](https://doc.traefik.io/traefik/providers/kubernetes-ingress/#publishedservice)
      enabled: true
      # -- Override path of Kubernetes Service used to copy status from. Format: namespace/servicename.
      # Default to Service deployed with this Chart.
      pathOverride: ""
    # -- Defines whether to use Native Kubernetes load-balancing mode by default.
    nativeLBByDefault: false

  kubernetesGateway:
    # -- Enable Traefik Gateway provider for Gateway API
    enabled: true
    # -- Toggles support for the Experimental Channel resources (Gateway API release channels documentation).
    # This option currently enables support for TCPRoute and TLSRoute.
    experimentalChannel: false
    # -- Array of namespaces to watch. If left empty, Traefik watches all namespaces.
    namespaces: []
    # -- A label selector can be defined to filter on specific GatewayClass objects only.
    labelselector: ""
    # -- Defines whether to use Native Kubernetes load-balancing mode by default.
    nativeLBByDefault: false
    statusAddress:
      # -- This IP will get copied to the Gateway status.addresses, and currently only supports one IP value (IPv4 or IPv6).
      ip: ""
      # -- This Hostname will get copied to the Gateway status.addresses.
      hostname: ""
      # -- The Kubernetes service to copy status addresses from. When using third parties tools like External-DNS, this option can be used to copy the service loadbalancer.status (containing the service's endpoints IPs) to the gateways. Default to Service of this Chart.
      service:
        name: "traefik"
        namespace: "traefik"

  file:
    # -- Create a file provider
    enabled: false
    # -- Allows Traefik to automatically watch for file changes
    watch: true
    # -- File content (YAML format, go template supported) (see https://doc.traefik.io/traefik/providers/file/)
    content: |
      http:
        middlewares:
          crowdsec:
            plugin:
              bouncer:
                Enabled: "true"
                logLevel: DEBUG
                crowdsecMode: stream
                crowdsecLapiScheme: https
                crowdsecLapiHost: crowdsec-service.crowdsec:8080
                crowdsecLapiKey: mysecretkey12345
                clientTrustedIPs:
                  - 192.168.1.0/24
                  - 10.13.13.0/16
          
          # auth:
          #   basicAuth:
          #   usersFile: "/etc/traefik/users"

        # routers:
        #   traefic-api:
        #     rule: "Host(`traefik.dartus.fr`) && (PathPrefix(`/api`))"
        #     service: "api@internal"
        #     middlewares:
        #     - crowdsec-test@docker
        #     - authelia@docker
        #   traefic-dash:
        #     rule: "Host(`traefik.dartus.fr`) && (PathPrefix(`/dashboard`))"
        #     service: "api@internal"
        #     middlewares:
        #     - crowdsec-test@docker
        #     - authelia@docker


#
# -- Add volumes to the traefik pod. The volume name will be passed to tpl.
# This can be used to mount a cert pair or a configmap that holds a config.toml file.
# After the volume has been mounted, add the configs into traefik by using the `additionalArguments` list below, eg:
# `additionalArguments:
# - "--providers.file.filename=/config/dynamic.toml"
# - "--ping"
# - "--ping.entrypoint=web"`
volumes: []
# - name: public-cert
#   mountPath: "/certs"
#   type: secret
# - name: '{ printf "%s-configs" .Release.Name }'
#   mountPath: "/config"
#   type: configMap

# -- Additional volumeMounts to add to the Traefik container
additionalVolumeMounts: []
# -- For instance when using a logshipper for access logs
# - name: traefik-logs
#   mountPath: /var/log/traefik

logs:
  general:
    # -- Set [logs format](https://doc.traefik.io/traefik/observability/logs/#format)
    format:  # @schema enum:["common", "json", null]; type:[string, null]; default: "common"
    # By default, the level is set to INFO.
    # -- Alternative logging levels are TRACE, DEBUG, INFO, WARN, ERROR, FATAL, and PANIC.
    level: "INFO"  # @schema enum:[TRACE,DEBUG,INFO,WARN,ERROR,FATAL,PANIC]; default: "INFO"
    # -- To write the logs into a log file, use the filePath option.
    filePath: ""
    # -- When set to true and format is common, it disables the colorized output.
    noColor: false
  access:
    # -- To enable access logs
    enabled: false
    # -- Set [access log format](https://doc.traefik.io/traefik/observability/access-logs/#format)
    format:  # @schema enum:["common", "json", null]; type:[string, null]; default: "common"
    # filePath: "/var/log/traefik/access.log
    # -- Set [bufferingSize](https://doc.traefik.io/traefik/observability/access-logs/#bufferingsize)
    bufferingSize:  # @schema type:[integer, null]
    # -- Set [filtering](https://docs.traefik.io/observability/access-logs/#filtering)
    filters:  # @schema additionalProperties: false
      # -- Set statusCodes, to limit the access logs to requests with a status codes in the specified range
      statuscodes: ""
      # -- Set retryAttempts, to keep the access logs when at least one retry has happened
      retryattempts: false
      # -- Set minDuration, to keep access logs when requests take longer than the specified duration
      minduration: ""
    # -- Enables accessLogs for internal resources. Default: false.
    addInternals: false
    fields:
      general:
        # -- Set default mode for fields.names
        defaultmode: keep  # @schema enum:[keep, drop, redact]; default: keep
        # -- Names of the fields to limit.
        names: {}
      # -- [Limit logged fields or headers](https://doc.traefik.io/traefik/observability/access-logs/#limiting-the-fieldsincluding-headers)
      headers:
        # -- Set default mode for fields.headers
        defaultmode: drop  # @schema enum:[keep, drop, redact]; default: drop
        names: {}

metrics:
  ## -- Enable metrics for internal resources. Default: false
  addInternals: false

  ## -- Prometheus is enabled by default.
  ## -- It can be disabled by setting "prometheus: null"
  prometheus:
    # -- Entry point used to expose metrics.
    entryPoint: metrics
    ## Enable metrics on entry points. Default: true
    addEntryPointsLabels:  # @schema type:[boolean, null]
    ## Enable metrics on routers. Default: false
    addRoutersLabels:  # @schema type:[boolean, null]
    ## Enable metrics on services. Default: true
    addServicesLabels:  # @schema type:[boolean, null]
    ## Buckets for latency metrics. Default="0.1,0.3,1.2,5.0"
    buckets: ""
    ## When manualRouting is true, it disables the default internal router in
    ## order to allow creating a custom router for prometheus@internal service.
    manualRouting: false
    service:
      # -- Create a dedicated metrics service to use with ServiceMonitor
      enabled: false
      labels: {}
      annotations: {}
    # -- When set to true, it won't check if Prometheus Operator CRDs are deployed
    disableAPICheck:  # @schema type:[boolean, null]
    serviceMonitor:
      # -- Enable optional CR for Prometheus Operator. See EXAMPLES.md for more details.
      enabled: false
      metricRelabelings: []
      relabelings: []
      jobLabel: ""
      interval: ""
      honorLabels: false
      scrapeTimeout: ""
      honorTimestamps: false
      enableHttp2: false
      followRedirects: false
      additionalLabels: {}
      namespace: ""
      namespaceSelector: {}
    prometheusRule:
      # -- Enable optional CR for Prometheus Operator. See EXAMPLES.md for more details.
      enabled: false
      additionalLabels: {}
      namespace: ""

  #  datadog:
  #    ## Address instructs exporter to send metrics to datadog-agent at this address.
  #    address: "127.0.0.1:8125"
  #    ## The interval used by the exporter to push metrics to datadog-agent. Default=10s
  #    # pushInterval: 30s
  #    ## The prefix to use for metrics collection. Default="traefik"
  #    # prefix: traefik
  #    ## Enable metrics on entry points. Default=true
  #    # addEntryPointsLabels: false
  #    ## Enable metrics on routers. Default=false
  #    # addRoutersLabels: true
  #    ## Enable metrics on services. Default=true
  #    # addServicesLabels: false
  #  influxdb2:
  #    ## Address instructs exporter to send metrics to influxdb v2 at this address.
  #    address: localhost:8086
  #    ## Token with which to connect to InfluxDB v2.
  #    token: xxx
  #    ## Organisation where metrics will be stored.
  #    org: ""
  #    ## Bucket where metrics will be stored.
  #    bucket: ""
  #    ## The interval used by the exporter to push metrics to influxdb. Default=10s
  #    # pushInterval: 30s
  #    ## Additional labels (influxdb tags) on all metrics.
  #    # additionalLabels:
  #    #   env: production
  #    #   foo: bar
  #    ## Enable metrics on entry points. Default=true
  #    # addEntryPointsLabels: false
  #    ## Enable metrics on routers. Default=false
  #    # addRoutersLabels: true
  #    ## Enable metrics on services. Default=true
  #    # addServicesLabels: false
  #  statsd:
  #    ## Address instructs exporter to send metrics to statsd at this address.
  #    address: localhost:8125
  #    ## The interval used by the exporter to push metrics to influxdb. Default=10s
  #    # pushInterval: 30s
  #    ## The prefix to use for metrics collection. Default="traefik"
  #    # prefix: traefik
  #    ## Enable metrics on entry points. Default=true
  #    # addEntryPointsLabels: false
  #    ## Enable metrics on routers. Default=false
  #    # addRoutersLabels: true
  #    ## Enable metrics on services. Default=true
  #    # addServicesLabels: false
  otlp:
    # -- Set to true in order to enable the OpenTelemetry metrics
    enabled: false
    # -- Enable metrics on entry points. Default: true
    addEntryPointsLabels:  # @schema type:[boolean, null]
    # -- Enable metrics on routers. Default: false
    addRoutersLabels:  # @schema type:[boolean, null]
    # -- Enable metrics on services. Default: true
    addServicesLabels:  # @schema type:[boolean, null]
    # -- Explicit boundaries for Histogram data points. Default: [.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10]
    explicitBoundaries: []
    # -- Interval at which metrics are sent to the OpenTelemetry Collector. Default: 10s
    pushInterval: ""
    http:
      # -- Set to true in order to send metrics to the OpenTelemetry Collector using HTTP.
      enabled: false
      # -- Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics
      endpoint: ""
      # -- Additional headers sent with metrics by the reporter to the OpenTelemetry Collector.
      headers: {}
      ## Defines the TLS configuration used by the reporter to send metrics to the OpenTelemetry Collector.
      tls:
        # -- The path to the certificate authority, it defaults to the system bundle.
        ca: ""
        # -- The path to the public certificate. When using this option, setting the key option is required.
        cert: ""
        # -- The path to the private key. When using this option, setting the cert option is required.
        key: ""
        # -- When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers.
        insecureSkipVerify:  # @schema type:[boolean, null]
    grpc:
      # -- Set to true in order to send metrics to the OpenTelemetry Collector using gRPC
      enabled: false
      # -- Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics
      endpoint: ""
      # -- Allows reporter to send metrics to the OpenTelemetry Collector without using a secured protocol.
      insecure: false
      ## Defines the TLS configuration used by the reporter to send metrics to the OpenTelemetry Collector.
      tls:
        # -- The path to the certificate authority, it defaults to the system bundle.
        ca: ""
        # -- The path to the public certificate. When using this option, setting the key option is required.
        cert: ""
        # -- The path to the private key. When using this option, setting the cert option is required.
        key: ""
        # -- When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers.
        insecureSkipVerify: false

## Tracing
# -- https://doc.traefik.io/traefik/observability/tracing/overview/
tracing:  # @schema additionalProperties: false
  # -- Enables tracing for internal resources. Default: false.
  addInternals: false
  # -- Service name used in selected backend. Default: traefik.
  serviceName:  # @schema type:[string, null]
  # -- Applies a list of shared key:value attributes on all spans.
  globalAttributes: {}
  # -- Defines the list of request headers to add as attributes. It applies to client and server kind spans.
  capturedRequestHeaders: []
  # -- Defines the list of response headers to add as attributes. It applies to client and server kind spans.
  capturedResponseHeaders: []
  # -- By default, all query parameters are redacted. Defines the list of query parameters to not redact.
  safeQueryParams: []
  # -- The proportion of requests to trace, specified between 0.0 and 1.0. Default: 1.0.
  sampleRate:  # @schema type:[number, null]; minimum:0; maximum:1
  otlp:
    # -- See https://doc.traefik.io/traefik/v3.0/observability/tracing/opentelemetry/
    enabled: false
    http:
      # -- Set to true in order to send metrics to the OpenTelemetry Collector using HTTP.
      enabled: false
      # -- Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics
      endpoint: ""
      # -- Additional headers sent with metrics by the reporter to the OpenTelemetry Collector.
      headers: {}
      ## Defines the TLS configuration used by the reporter to send metrics to the OpenTelemetry Collector.
      tls:
        # -- The path to the certificate authority, it defaults to the system bundle.
        ca: ""
        # -- The path to the public certificate. When using this option, setting the key option is required.
        cert: ""
        # -- The path to the private key. When using this option, setting the cert option is required.
        key: ""
        # -- When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers.
        insecureSkipVerify: false
    grpc:
      # -- Set to true in order to send metrics to the OpenTelemetry Collector using gRPC
      enabled: false
      # -- Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics
      endpoint: ""
      # -- Allows reporter to send metrics to the OpenTelemetry Collector without using a secured protocol.
      insecure: false
      ## Defines the TLS configuration used by the reporter to send metrics to the OpenTelemetry Collector.
      tls:
        # -- The path to the certificate authority, it defaults to the system bundle.
        ca: ""
        # -- The path to the public certificate. When using this option, setting the key option is required.
        cert: ""
        # -- The path to the private key. When using this option, setting the cert option is required.
        key: ""
        # -- When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers.
        insecureSkipVerify: false

# -- Global command arguments to be passed to all traefik's pods
globalArguments:
- "--global.checknewversion"
- "--global.sendanonymoususage"

# -- Additional arguments to be passed at Traefik's binary
# See [CLI Reference](https://docs.traefik.io/reference/static-configuration/cli/)
# Use curly braces to pass values: `helm install --set="additionalArguments={--providers.kubernetesingress.ingressclass=traefik-internal,--log.level=DEBUG}"`
additionalArguments: []
#  - "--providers.kubernetesingress.ingressclass=traefik-internal"
#  - "--log.level=DEBUG"

# -- Additional Environment variables to be passed to Traefik's binary
# @default -- See _values.yaml_
env: []

# -- Environment variables to be passed to Traefik's binary from configMaps or secrets
envFrom: []

ports:
  traefik:
    port: 9000
    # -- Use hostPort if set.
    hostPort:  # @schema type:[integer, null]; minimum:0
    # -- Use hostIP if set. If not set, Kubernetes will default to 0.0.0.0, which
    # means it's listening on all your interfaces and all your IPs. You may want
    # to set this value if you need traefik to listen on specific interface
    # only.
    hostIP:  # @schema type:[string, null]

    # Defines whether the port is exposed if service.type is LoadBalancer or
    # NodePort.
    #
    # -- You SHOULD NOT expose the traefik port on production deployments.
    # If you want to access it from outside your cluster,
    # use `kubectl port-forward` or create a secure ingress
    expose:
      default: false
    # -- The exposed port for this service
    exposedPort: 9000
    # -- The port protocol (TCP/UDP)
    protocol: TCP
  web:
    ## -- Enable this entrypoint as a default entrypoint. When a service doesn't explicitly set an entrypoint it will only use this entrypoint.
    # asDefault: true
    port: 9000
    # hostPort: 8000
    # containerPort: 8000
    expose:
      default: true
    exposedPort: 80
    ## -- Different target traefik port on the cluster, useful for IP type LB
    targetPort:  # @schema type:[string, integer, null]; minimum:0
    # The port protocol (TCP/UDP)
    protocol: TCP
    # -- See [upstream documentation](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
    nodePort:  # @schema type:[integer, null]; minimum:0
    # Port Redirections
    # Added in 2.2, you can make permanent redirects via entrypoints.
    # https://docs.traefik.io/routing/entrypoints/#redirection
    redirectTo: {}
    forwardedHeaders:
    # -- Trust forwarded headers information (X-Forwarded-*).
      trustedIPs: []
      insecure: false
    proxyProtocol:
    # -- Enable the Proxy Protocol header parsing for the entry point
      trustedIPs: []
      insecure: false
    # -- Set transport settings for the entrypoint; see also
    # https://doc.traefik.io/traefik/routing/entrypoints/#transport
    transport:
      respondingTimeouts:
        readTimeout:   # @schema type:[string, integer, null]
        writeTimeout:  # @schema type:[string, integer, null]
        idleTimeout:   # @schema type:[string, integer, null]
      lifeCycle:
        requestAcceptGraceTimeout:  # @schema type:[string, integer, null]
        graceTimeOut:               # @schema type:[string, integer, null]
      keepAliveMaxRequests:         # @schema type:[integer, null]; minimum:0
      keepAliveMaxTime:             # @schema type:[string, integer, null]
  websecure:
    ## -- Enable this entrypoint as a default entrypoint. When a service doesn't explicitly set an entrypoint it will only use this entrypoint.
    # asDefault: true
    port: 8443
    hostPort:  # @schema type:[integer, null]; minimum:0
    containerPort:  # @schema type:[integer, null]; minimum:0
    expose:
      default: true
    exposedPort: 443
    ## -- Different target traefik port on the cluster, useful for IP type LB
    targetPort:  # @schema type:[string, integer, null]; minimum:0
    ## -- The port protocol (TCP/UDP)
    protocol: TCP
    # -- See [upstream documentation](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
    nodePort:  # @schema type:[integer, null]; minimum:0
    # -- See [upstream documentation](https://kubernetes.io/docs/concepts/services-networking/service/#application-protocol)
    appProtocol:  # @schema type:[string, null]
    # -- See [upstream documentation](https://doc.traefik.io/traefik/routing/entrypoints/#allowacmebypass)
    allowACMEByPass: false
    http3:
    ## -- Enable HTTP/3 on the entrypoint
    ## Enabling it will also enable http3 experimental feature
    ## https://doc.traefik.io/traefik/routing/entrypoints/#http3
    ## There are known limitations when trying to listen on same ports for
    ## TCP & UDP (Http3). There is a workaround in this chart using dual Service.
    ## https://github.com/kubernetes/kubernetes/issues/47249#issuecomment-587960741
      enabled: false
      advertisedPort:  # @schema type:[integer, null]; minimum:0
    forwardedHeaders:
    # -- Trust forwarded headers information (X-Forwarded-*).
      trustedIPs: []
      insecure: false
    proxyProtocol:
    # -- Enable the Proxy Protocol header parsing for the entry point
      trustedIPs: []
      insecure: false
    # -- See [upstream documentation](https://doc.traefik.io/traefik/routing/entrypoints/#transport)
    transport:
      respondingTimeouts:
        readTimeout:   # @schema type:[string, integer, null]
        writeTimeout:  # @schema type:[string, integer, null]
        idleTimeout:   # @schema type:[string, integer, null]
      lifeCycle:
        requestAcceptGraceTimeout:  # @schema type:[string, integer, null]
        graceTimeOut:               # @schema type:[string, integer, null]
      keepAliveMaxRequests:         # @schema type:[integer, null]; minimum:0
      keepAliveMaxTime:             # @schema type:[string, integer, null]
    # --  See [upstream documentation](https://doc.traefik.io/traefik/routing/entrypoints/#tls)
    tls:
      enabled: true
      options: ""
      certResolver: ""
      domains: []
    # -- One can apply Middlewares on an entrypoint
    # https://doc.traefik.io/traefik/middlewares/overview/
    # https://doc.traefik.io/traefik/routing/entrypoints/#middlewares
    # -- /!\ It introduces here a link between your static configuration and your dynamic configuration /!\
    # It follows the provider naming convention: https://doc.traefik.io/traefik/providers/overview/#provider-namespace
    #   - namespace-name1@kubernetescrd
    #   - namespace-name2@kubernetescrd
    middlewares: []
  metrics:
    # -- When using hostNetwork, use another port to avoid conflict with node exporter:
    # https://github.com/prometheus/prometheus/wiki/Default-port-allocations
    port: 9100
    # -- You may not want to expose the metrics port on production deployments.
    # If you want to access it from outside your cluster,
    # use `kubectl port-forward` or create a secure ingress
    expose:
      default: false
    # -- The exposed port for this service
    exposedPort: 9100
    # -- The port protocol (TCP/UDP)
    protocol: TCP

# -- TLS Options are created as [TLSOption CRDs](https://doc.traefik.io/traefik/https/tls/#tls-options)
# When using `labelSelector`, you'll need to set labels on tlsOption accordingly.
# See EXAMPLE.md for details.
tlsOptions: {}

# -- TLS Store are created as [TLSStore CRDs](https://doc.traefik.io/traefik/https/tls/#default-certificate). This is useful if you want to set a default certificate. See EXAMPLE.md for details.
tlsStore: {}

service:
  enabled: true
  ## -- Single service is using `MixedProtocolLBService` feature gate.
  ## -- When set to false, it will create two Service, one for TCP and one for UDP.
  single: true
  type: LoadBalancer
  # -- Additional annotations applied to both TCP and UDP services (e.g. for cloud provider specific config)
  annotations: 
    metallb.universe.tf/loadBalancerIPs: 192.168.1.4
  # -- Additional annotations for TCP service only
  annotationsTCP: {}
  # -- Additional annotations for UDP service only
  annotationsUDP: {}
  # -- Additional service labels (e.g. for filtering Service by custom labels)
  labels: {}
  # -- Additional entries here will be added to the service spec.
  # -- Cannot contain type, selector or ports entries.
  spec: {}
  # externalTrafficPolicy: Cluster
  # loadBalancerIP: "1.2.3.4"
  # clusterIP: "2.3.4.5"
  loadBalancerSourceRanges: []
  # - 192.168.0.1/32
  # - 172.16.0.0/16
  ## -- Class of the load balancer implementation
  # loadBalancerClass: service.k8s.aws/nlb
  externalIPs: []
  # - 1.2.3.4
  ## One of SingleStack, PreferDualStack, or RequireDualStack.
  # ipFamilyPolicy: SingleStack
  ## List of IP families (e.g. IPv4 and/or IPv6).
  ## ref: https://kubernetes.io/docs/concepts/services-networking/dual-stack/#services
  # ipFamilies:
  #   - IPv4
  #   - IPv6
  ##
  additionalServices: {}
  ## -- An additional and optional internal Service.
  ## Same parameters as external Service
  # internal:
  #   type: ClusterIP
  #   # labels: {}
  #   # annotations: {}
  #   # spec: {}
  #   # loadBalancerSourceRanges: []
  #   # externalIPs: []
  #   # ipFamilies: [ "IPv4","IPv6" ]

autoscaling:
  # -- Create HorizontalPodAutoscaler object.
  # See EXAMPLES.md for more details.
  enabled: false

persistence:
  # -- Enable persistence using Persistent Volume Claims
  # ref: http://kubernetes.io/docs/user-guide/persistent-volumes/.
  # It can be used to store TLS certificates along with `certificatesResolvers.<name>.acme.storage`  option
  enabled: false
  name: data
  existingClaim: ""
  accessMode: ReadWriteOnce
  size: 128Mi
  storageClass: ""
  volumeName: ""
  path: /data
  annotations: {}
  # -- Only mount a subpath of the Volume into the pod
  subPath: ""

# -- Certificates resolvers configuration.
# Ref: https://doc.traefik.io/traefik/https/acme/#certificate-resolvers
# See EXAMPLES.md for more details.
certificatesResolvers: {}

# -- If hostNetwork is true, runs traefik in the host network namespace
# To prevent unschedulable pods due to port collisions, if hostNetwork=true
# and replicas>1, a pod anti-affinity is recommended and will be set if the
# affinity is left as default.
hostNetwork: false

# -- Whether Role Based Access Control objects like roles and rolebindings should be created
rbac:  # @schema additionalProperties: false
  enabled: true
  # When set to true:
  # 1. It switches respectively the use of `ClusterRole` and `ClusterRoleBinding` to `Role` and `RoleBinding`.
  # 2. It adds `disableIngressClassLookup` on Kubernetes Ingress with Traefik Proxy v3 until v3.1.4
  # 3. It adds `disableClusterScopeResources` on Ingress and CRD (Kubernetes) providers with Traefik Proxy v3.1.2+
  # **NOTE**: `IngressClass`, `NodePortLB` and **Gateway** provider cannot be used with namespaced RBAC.
  # See [upstream documentation](https://doc.traefik.io/traefik/providers/kubernetes-ingress/#disableclusterscoperesources) for more details.
  namespaced: false
  # Enable user-facing roles
  # https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles
  aggregateTo: []
  # List of Kubernetes secrets that are accessible for Traefik. If empty, then access is granted to every secret.
  secretResourceNames: []

# -- Enable to create a PodSecurityPolicy and assign it to the Service Account via RoleBinding or ClusterRoleBinding
podSecurityPolicy:
  enabled: false

# -- The service account the pods will use to interact with the Kubernetes API
serviceAccount:  # @schema additionalProperties: false
  # If set, an existing service account is used
  # If not set, a service account is created automatically using the fullname template
  name: ""

# -- Additional serviceAccount annotations (e.g. for oidc authentication)
serviceAccountAnnotations: {}

# -- [Resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) for `traefik` container.
resources: {}

# -- This example pod anti-affinity forces the scheduler to put traefik pods
# -- on nodes where no other traefik pods are scheduled.
# It should be used when hostNetwork: true to prevent port conflicts
affinity: {}
#  podAntiAffinity:
#    requiredDuringSchedulingIgnoredDuringExecution:
#      - labelSelector:
#          matchLabels:
#            app.kubernetes.io/name: {template "traefik.name" . }
#            app.kubernetes.io/instance: {`'{ .Release.Name }}-{ .Release.Namespace }'`}
#        topologyKey: kubernetes.io/hostname

# -- nodeSelector is the simplest recommended form of node selection constraint.
nodeSelector: {}
# -- Tolerations allow the scheduler to schedule pods with matching taints.
tolerations: []
# -- You can use topology spread constraints to control
# how Pods are spread across your cluster among failure-domains.
topologySpreadConstraints: []
# This example topologySpreadConstraints forces the scheduler to put traefik pods
# on nodes where no other traefik pods are scheduled.
#  - labelSelector:
#      matchLabels:
#        app.kubernetes.io/name: '{ template "traefik.name" . }'
#    maxSkew: 1
#    topologyKey: kubernetes.io/hostname
#    whenUnsatisfiable: DoNotSchedule

# -- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
priorityClassName: ""

# -- [SecurityContext](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context-1)
# @default -- See _values.yaml_
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
  readOnlyRootFilesystem: true

# -- [Pod Security Context](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context)
# @default -- See _values.yaml_
podSecurityContext:
  runAsGroup: 65532
  runAsNonRoot: true
  runAsUser: 65532

#
# -- Extra objects to deploy (value evaluated as a template)
#
# In some cases, it can avoid the need for additional, extended or adhoc deployments.
# See #595 for more details and traefik/tests/values/extra.yaml for example.
extraObjects: []

# -- This field override the default Release Namespace for Helm.
# It will not affect optional CRDs such as `ServiceMonitor` and `PrometheusRules`
namespaceOverride: ""

## -- This field override the default app.kubernetes.io/instance label for all Objects.
instanceLabelOverride: ""

# Traefik Hub configuration. See https://doc.traefik.io/traefik-hub/
hub:
  # -- Name of `Secret` with key 'token' set to a valid license token.
  # It enables API Gateway.
  token: ""
  apimanagement:
    # -- Set to true in order to enable API Management. Requires a valid license token.
    enabled: false
    admission:
      # -- WebHook admission server listen address. Default: "0.0.0.0:9943".
      listenAddr: ""
      # -- Certificate of the WebHook admission server. Default: "hub-agent-cert".
      secretName: ""

  redis:
    # -- Enable Redis Cluster. Default: true.
    cluster:    # @schema type:[boolean, null]
    # -- Database used to store information. Default: "0".
    database:   # @schema type:[string, null]
    # -- Endpoints of the Redis instances to connect to. Default: "".
    endpoints: ""
    # -- The username to use when connecting to Redis endpoints. Default: "".
    username: ""
    # -- The password to use when connecting to Redis endpoints. Default: "".
    password: ""
    sentinel:
      # -- Name of the set of main nodes to use for main selection. Required when using Sentinel. Default: "".
      masterset: ""
      # -- Username to use for sentinel authentication (can be different from endpoint username). Default: "".
      username: ""
      # -- Password to use for sentinel authentication (can be different from endpoint password). Default: "".
      password: ""
    # -- Timeout applied on connection with redis. Default: "0s".
    timeout: ""
    tls:
      # -- Path to the certificate authority used for the secured connection.
      ca: ""
      # -- Path to the public certificate used for the secure connection.
      cert: ""
      # -- Path to the private key used for the secure connection.
      key: ""
      # -- When insecureSkipVerify is set to true, the TLS connection accepts any certificate presented by the server. Default: false.
      insecureSkipVerify: false
  # Enable export of errors logs to the platform. Default: true.
  sendlogs:  # @schema type:[boolean, null]
  {{- end }}
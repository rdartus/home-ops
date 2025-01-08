{{- define "helmValues.traefik" }}

# Default values for Traefik
image:
  # -- Traefik image host registry
  registry: docker.io
  # -- Traefik image repository
  repository: traefik
  # -- defaults to appVersion
  tag: ""
  # -- Traefik image pull policy
  pullPolicy: IfNotPresent

# -- Add additional label to all resources
commonLabels: {}

#
# Configure the deployment
#
deployment:
  # -- Enable deployment
  enabled: true
  # -- Deployment or DaemonSet
  kind: Deployment
  # -- Number of pods of the deployment (only applies when kind == Deployment)
  replicas: 1
  # -- Number of old history to retain to allow rollback (If not set, default Kubernetes value is set to 10)
  # revisionHistoryLimit: 1
  # -- Amount of time (in seconds) before Kubernetes will send the SIGKILL signal if Traefik does not shut down
  terminationGracePeriodSeconds: 60
  # -- The minimum number of seconds Traefik needs to be up and running before the DaemonSet/Deployment controller considers it available
  minReadySeconds: 0
  ## Override the liveness/readiness port. This is useful to integrate traefik
  ## with an external Load Balancer that performs healthchecks.
  ## Default: ports.traefik.port
  # healthchecksPort: 9000
  ## Override the liveness/readiness host. Useful for getting ping to respond on non-default entryPoint.
  ## Default: ports.traefik.hostIP if set, otherwise Pod IP
  # healthchecksHost: localhost
  ## Override the liveness/readiness scheme. Useful for getting ping to
  ## respond on websecure entryPoint.
  # healthchecksScheme: HTTPS
  ## Override the readiness path.
  ## Default: /ping
  # readinessPath: /ping
  # Override the liveness path.
  # Default: /ping
  # livenessPath: /ping
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
  #   securityContext:
  #     runAsNonRoot: true
  #     runAsGroup: 65532
  #     runAsUser: 65532
  #   volumeMounts:
  #     - name: data
  #       mountPath: /data
  # -- Use process namespace sharing
  shareProcessNamespace: false
  # -- Custom pod DNS policy. Apply if `hostNetwork: true`
  # dnsPolicy: ClusterFirstWithHostNet
  dnsConfig: {}
  # nameservers:
  #   - 192.0.2.1 # this is an example
  # searches:
  #   - ns1.svc.cluster-domain.example
  #   - my.dns.search.suffix
  # options:
  #   - name: ndots
  #     value: "2"
  #   - name: edns0
  # -- Additional imagePullSecrets
  imagePullSecrets: []
  # - name: myRegistryKeySecretName
  # -- Pod lifecycle actions
  lifecycle: {}
  # preStop:
  #   exec:
  #     command: ["/bin/sh", "-c", "sleep 40"]
  # postStart:
  #   httpGet:
  #     path: /ping
  #     port: 9000
  #     host: localhost
  #     scheme: HTTP
  # -- Set a runtimeClassName on pod
  runtimeClassName:

# -- Pod disruption budget
podDisruptionBudget:
  enabled: false
  # maxUnavailable: 1
  # maxUnavailable: 33%
  # minAvailable: 0
  # minAvailable: 25%

# -- Create a default IngressClass for Traefik
ingressClass:
  enabled: true
  isDefaultClass: true
  name: traefik-ingresses

core:
  # -- Can be used to use globally v2 router syntax
  # See https://doc.traefik.io/traefik/v3.0/migration/v2-to-v3/#new-v3-syntax-notable-changes
  defaultRuleSyntax:

# Traefik experimental features
experimental:
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
    enabled: false
    ## Routes are restricted to namespace of the gateway by default.
    ## https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.FromNamespaces
    # namespacePolicy: All
    # certificate:
    #   group: "core"
    #   kind: "Secret"
    #   name: "mysecret"
    # -- By default, Gateway would be created to the Namespace you are deploying Traefik to.
    # You may create that Gateway in another namespace, setting its name below:
    # namespace: default
    # Additional gateway annotations (e.g. for cert-manager.io/issuer)
    # annotations:
    #   cert-manager.io/issuer: letsencrypt

## Create an IngressRoute for the dashboard
ingressRoute:
  dashboard:
    # -- Create an IngressRoute for the dashboard
    enabled: true
    # -- Additional ingressRoute annotations (e.g. for kubernetes.io/ingress.class)
    annotations: {}
    # -- Additional ingressRoute labels (e.g. for filtering IngressRoute by custom labels)
    labels: {}
    # -- The router match rule used for the dashboard ingressRoute
    matchRule: PathPrefix(`/dashboard`) || PathPrefix(`/api`)
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
    # -- Specify the allowed entrypoints to use for the healthcheck ingress route, (e.g. traefik, web, websecure).
    # By default, it's using traefik entrypoint, which is not exposed.
    entryPoints: ["traefik"]
    # -- Additional ingressRoute middlewares (e.g. for authentication)
    middlewares: []
    # -- TLS options (e.g. secret containing certificate)
    tls: {}

updateStrategy:
  # -- Customize updateStrategy: RollingUpdate or OnDelete
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1

readinessProbe:
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
livenessProbe:
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

# -- Define Startup Probe for container: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes
# eg.
# `startupProbe:
#   exec:
#     command:
#       - mycommand
#       - foo
#   initialDelaySeconds: 5
#   periodSeconds: 5`
startupProbe:

providers:
  kubernetesCRD:
    # -- Load Kubernetes IngressRoute provider
    enabled: true
    # -- Allows IngressRoute to reference resources in namespace other than theirs
    allowCrossNamespace: false
    # -- Allows to reference ExternalName services in IngressRoute
    allowExternalNameServices: false
    # -- Allows to return 503 when there is no endpoints available
    allowEmptyServices: false
    # ingressClass: traefik-internal
    # labelSelector: environment=production,method=traefik
    # -- Array of namespaces to watch. If left empty, Traefik watches all namespaces.
    namespaces: []
    # - "default"

  kubernetesIngress:
    # -- Load Kubernetes Ingress provider
    enabled: true
    # -- Allows to reference ExternalName services in Ingress
    allowExternalNameServices: false
    # -- Allows to return 503 when there is no endpoints available
    allowEmptyServices: false
    # ingressClass: traefik-internal
    # labelSelector: environment=production,method=traefik
    # -- Array of namespaces to watch. If left empty, Traefik watches all namespaces.
    namespaces: []
    # - "default"
    # Disable cluster IngressClass Lookup - Requires Traefik V3.
    # When combined with rbac.namespaced: true, ClusterRole will not be created and ingresses must use kubernetes.io/ingress.class annotation instead of spec.ingressClassName.
    disableIngressClassLookup: false
    # IP used for Kubernetes Ingress endpoints
    publishedService:
      enabled: true
      # Published Kubernetes Service to copy status from. Format: namespace/servicename
      # By default this Traefik service
      # pathOverride: ""

  file:
    # -- Create a file provider
    enabled: false
    # -- Allows Traefik to automatically watch for file changes
    watch: true
    # -- File content (YAML format, go template supported) (see https://doc.traefik.io/traefik/providers/file/)
    content: 
      http:
        routers:
          traefic-api:
            rule: "Host(`traefik.dartus.fr`) && (PathPrefix(`/api`))"
            service: "api@internal"
            middlewares:
            - authentik@file
          traefic-dash:
            rule: "Host(`traefik.dartus.fr`) && (PathPrefix(`/dashboard`))"
            service: "api@internal"
            middlewares:
            - authentik@file
        middlewares:
          authentik:
              forwardAuth:
                  address: http://outpost.company:9000/outpost.goauthentik.io/auth/traefik
                  trustForwardHeader: true
                  authResponseHeaders:
                      - X-authentik-username
                      - X-authentik-groups
                      - X-authentik-entitlements
                      - X-authentik-email
                      - X-authentik-name
                      - X-authentik-uid
                      - X-authentik-jwt
                      - X-authentik-meta-jwks
                      - X-authentik-meta-outpost
                      - X-authentik-meta-provider
                      - X-authentik-meta-app
                      - X-authentik-meta-version
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
# - name: '{{ printf "%s-configs" .Release.Name }}'
#   mountPath: "/config"
#   type: configMap

# -- Additional volumeMounts to add to the Traefik container
additionalVolumeMounts: []
# -- For instance when using a logshipper for access logs
# - name: traefik-logs
#   mountPath: /var/log/traefik

logs:
  general:
    # -- By default, the logs use a text format (common), but you can
    # also ask for the json format in the format option
    # format: json
    # By default, the level is set to ERROR.
    # -- Alternative logging levels are DEBUG, PANIC, FATAL, ERROR, WARN, and INFO.
    level: DEBUG
  access:
    # -- To enable access logs
    enabled: true
    ## By default, logs are written using the Common Log Format (CLF) on stdout.
    ## To write logs in JSON, use json in the format option.
    ## If the given format is unsupported, the default (CLF) is used instead.
    # format: json
    # filePath: "/var/log/traefik/access.log
    ## To write the logs in an asynchronous fashion, specify a bufferingSize option.
    ## This option represents the number of log lines Traefik will keep in memory before writing
    ## them to the selected output. In some cases, this option can greatly help performances.
    # bufferingSize: 100
    ## Filtering
    # -- https://docs.traefik.io/observability/access-logs/#filtering
    filters: {}
    # statuscodes: "200,300-302"
    # retryattempts: true
    # minduration: 10ms
    # -- Enables accessLogs for internal resources. Default: false.
    addInternals:
    fields:
      general:
        # -- Available modes: keep, drop, redact.
        defaultmode: keep
        # -- Names of the fields to limit.
        names: {}
        ## Examples:
        # ClientUsername: drop
      headers:
        # -- Available modes: keep, drop, redact.
        defaultmode: drop
        # -- Names of the headers to limit.
        names: {}
        ## Examples:
        # User-Agent: redact
        # Authorization: drop
        # Content-Type: keep

metrics:
  ## -- Enable metrics for internal resources. Default: false
  addInternals:

  ## -- Prometheus is enabled by default.
  ## -- It can be disabled by setting "prometheus: null"
  prometheus:
    # -- Entry point used to expose metrics.
    entryPoint: metrics
    ## Enable metrics on entry points. Default=true
    # addEntryPointsLabels: false
    ## Enable metrics on routers. Default=false
    # addRoutersLabels: true
    ## Enable metrics on services. Default=true
    # addServicesLabels: false
    ## Buckets for latency metrics. Default="0.1,0.3,1.2,5.0"
    # buckets: "0.5,1.0,2.5"
    ## When manualRouting is true, it disables the default internal router in
    ## order to allow creating a custom router for prometheus@internal service.
    # manualRouting: true
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
    addEntryPointsLabels:
    # -- Enable metrics on routers. Default: false
    addRoutersLabels:
    # -- Enable metrics on services. Default: true
    addServicesLabels:
    # -- Explicit boundaries for Histogram data points. Default: [.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10]
    explicitBoundaries:
    # -- Interval at which metrics are sent to the OpenTelemetry Collector. Default: 10s
    pushInterval:
    http:
      # -- Set to true in order to send metrics to the OpenTelemetry Collector using HTTP.
      enabled: false
      # -- Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics
      endpoint:
      # -- Additional headers sent with metrics by the reporter to the OpenTelemetry Collector.
      headers:
      ## Defines the TLS configuration used by the reporter to send metrics to the OpenTelemetry Collector.
      tls:
        # -- The path to the certificate authority, it defaults to the system bundle.
        ca:
        # -- The path to the public certificate. When using this option, setting the key option is required.
        cert:
        # -- The path to the private key. When using this option, setting the cert option is required.
        key:
        # -- When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers.
        insecureSkipVerify:
    grpc:
      # -- Set to true in order to send metrics to the OpenTelemetry Collector using gRPC
      enabled: false
      # -- Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics
      endpoint:
      # -- Allows reporter to send metrics to the OpenTelemetry Collector without using a secured protocol.
      insecure:
      ## Defines the TLS configuration used by the reporter to send metrics to the OpenTelemetry Collector.
      tls:
        # -- The path to the certificate authority, it defaults to the system bundle.
        ca:
        # -- The path to the public certificate. When using this option, setting the key option is required.
        cert:
        # -- The path to the private key. When using this option, setting the cert option is required.
        key:
        # -- When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers.
        insecureSkipVerify:

  ## -- enable optional CRDs for Prometheus Operator
  ##
  ## Create a dedicated metrics service for use with ServiceMonitor
  #  service:
  #    enabled: false
  #    labels: {}
  #    annotations: {}
  ## When set to true, it won't check if Prometheus Operator CRDs are deployed
  #  disableAPICheck: false
  #  serviceMonitor:
  #    metricRelabelings: []
  #      - sourceLabels: [__name__]
  #        separator: ;
  #        regex: ^fluentd_output_status_buffer_(oldest|newest)_.+
  #        replacement: $1
  #        action: drop
  #    relabelings: []
  #      - sourceLabels: [__meta_kubernetes_pod_node_name]
  #        separator: ;
  #        regex: ^(.*)$
  #        targetLabel: nodename
  #        replacement: $1
  #        action: replace
  #    jobLabel: traefik
  #    interval: 30s
  #    honorLabels: true
  #    # (Optional)
  #    # scrapeTimeout: 5s
  #    # honorTimestamps: true
  #    # enableHttp2: true
  #    # followRedirects: true
  #    # additionalLabels:
  #    #   foo: bar
  #    # namespace: "another-namespace"
  #    # namespaceSelector: {}
  #  prometheusRule:
  #    additionalLabels: {}
  #    namespace: "another-namespace"
  #    rules:
  #      - alert: TraefikDown
  #        expr: up{job="traefik"} == 0
  #        for: 5m
  #        labels:
  #          context: traefik
  #          severity: warning
  #        annotations:
  #          summary: "Traefik Down"
  #          description: "{{`{{ $labels.pod }}`}} on {{`{{ $labels.nodename }}`}} is down"

## Tracing
# -- https://doc.traefik.io/traefik/observability/tracing/overview/
tracing:
  # -- Enables tracing for internal resources. Default: false.
  addInternals:
  otlp:
    # -- See https://doc.traefik.io/traefik/v3.0/observability/tracing/opentelemetry/
    enabled: false
    http:
      # -- Set to true in order to send metrics to the OpenTelemetry Collector using HTTP.
      enabled: false
      # -- Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics
      endpoint:
      # -- Additional headers sent with metrics by the reporter to the OpenTelemetry Collector.
      headers:
      ## Defines the TLS configuration used by the reporter to send metrics to the OpenTelemetry Collector.
      tls:
        # -- The path to the certificate authority, it defaults to the system bundle.
        ca:
        # -- The path to the public certificate. When using this option, setting the key option is required.
        cert:
        # -- The path to the private key. When using this option, setting the cert option is required.
        key:
        # -- When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers.
        insecureSkipVerify:
    grpc:
      # -- Set to true in order to send metrics to the OpenTelemetry Collector using gRPC
      enabled: false
      # -- Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics
      endpoint:
      # -- Allows reporter to send metrics to the OpenTelemetry Collector without using a secured protocol.
      insecure:
      ## Defines the TLS configuration used by the reporter to send metrics to the OpenTelemetry Collector.
      tls:
        # -- The path to the certificate authority, it defaults to the system bundle.
        ca:
        # -- The path to the public certificate. When using this option, setting the key option is required.
        cert:
        # -- The path to the private key. When using this option, setting the cert option is required.
        key:
        # -- When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers.
        insecureSkipVerify:

# -- Global command arguments to be passed to all traefik's pods
globalArguments:
- "--global.checknewversion"
- "--global.sendanonymoususage"

#
# Configure Traefik static configuration
# -- Additional arguments to be passed at Traefik's binary
# All available options available on https://docs.traefik.io/reference/static-configuration/cli/
## Use curly braces to pass values: `helm install --set="additionalArguments={--providers.kubernetesingress.ingressclass=traefik-internal,--log.level=DEBUG}"`
additionalArguments: []
#  - "--providers.kubernetesingress.ingressclass=traefik-internal"
#  - "--log.level=DEBUG"

# -- Environment variables to be passed to Traefik's binary
env:
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
# - name: SOME_VAR
#   value: some-var-value
# - name: SOME_VAR_FROM_CONFIG_MAP
#   valueFrom:
#     configMapRef:
#       name: configmap-name
#       key: config-key
# - name: SOME_SECRET
#   valueFrom:
#     secretKeyRef:
#       name: secret-name
#       key: secret-key

# -- Environment variables to be passed to Traefik's binary from configMaps or secrets
envFrom: []
# - configMapRef:
#     name: config-map-name
# - secretRef:
#     name: secret-name

ports:
  traefik:
    port: 9000
    # -- Use hostPort if set.
    # hostPort: 9000
    #
    # -- Use hostIP if set. If not set, Kubernetes will default to 0.0.0.0, which
    # means it's listening on all your interfaces and all your IPs. You may want
    # to set this value if you need traefik to listen on specific interface
    # only.
    # hostIP: 192.168.100.10

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
    port: 8000
    # hostPort: 8000
    # containerPort: 8000
    expose:
      default: true
    exposedPort: 80
    ## -- Different target traefik port on the cluster, useful for IP type LB
    # targetPort: 80
    # The port protocol (TCP/UDP)
    protocol: TCP
    # -- Use nodeport if set. This is useful if you have configured Traefik in a
    # LoadBalancer.
    # nodePort: 32080
    # Port Redirections
    # Added in 2.2, you can make permanent redirects via entrypoints.
    # https://docs.traefik.io/routing/entrypoints/#redirection
    # redirectTo:
    #   port: websecure
    #   (Optional)
    #   priority: 10
    #
    # -- Trust forwarded headers information (X-Forwarded-*).
    # forwardedHeaders:
    #   trustedIPs: []
    #   insecure: false
    #
    # -- Enable the Proxy Protocol header parsing for the entry point
    # proxyProtocol:
    #   trustedIPs: []
    #   insecure: false
    #
    # -- Set transport settings for the entrypoint; see also
    # https://doc.traefik.io/traefik/routing/entrypoints/#transport
    transport:
      respondingTimeouts:
        readTimeout:
        writeTimeout:
        idleTimeout:
      lifeCycle:
        requestAcceptGraceTimeout:
        graceTimeOut:
      keepAliveMaxRequests:
      keepAliveMaxTime:
  websecure:
    ## -- Enable this entrypoint as a default entrypoint. When a service doesn't explicitly set an entrypoint it will only use this entrypoint.
    # asDefault: true
    port: 8443
    # hostPort: 8443
    # containerPort: 8443
    expose:
      default: true
    exposedPort: 443
    ## -- Different target traefik port on the cluster, useful for IP type LB
    # targetPort: 80
    ## -- The port protocol (TCP/UDP)
    protocol: TCP
    # nodePort: 32443
    ## -- Specify an application protocol. This may be used as a hint for a Layer 7 load balancer.
    # appProtocol: https
    #
    ## -- Enable HTTP/3 on the entrypoint
    ## Enabling it will also enable http3 experimental feature
    ## https://doc.traefik.io/traefik/routing/entrypoints/#http3
    ## There are known limitations when trying to listen on same ports for
    ## TCP & UDP (Http3). There is a workaround in this chart using dual Service.
    ## https://github.com/kubernetes/kubernetes/issues/47249#issuecomment-587960741
    http3:
      enabled: false
    # advertisedPort: 4443
    #
    # -- Trust forwarded headers information (X-Forwarded-*).
    # forwardedHeaders:
    #   trustedIPs: []
    #   insecure: false
    #
    # -- Enable the Proxy Protocol header parsing for the entry point
    # proxyProtocol:
    #   trustedIPs: []
    #   insecure: false
    #
    # -- Set transport settings for the entrypoint; see also
    # https://doc.traefik.io/traefik/routing/entrypoints/#transport
    transport:
      respondingTimeouts:
        readTimeout:
        writeTimeout:
        idleTimeout:
      lifeCycle:
        requestAcceptGraceTimeout:
        graceTimeOut:
      keepAliveMaxRequests:
      keepAliveMaxTime:
    #
    ## Set TLS at the entrypoint
    ## https://doc.traefik.io/traefik/routing/entrypoints/#tls
    tls:
      enabled: true
      # this is the name of a TLSOption definition
      options: ""
      certResolver: ""
      domains: []
      # - main: example.com
      #   sans:
      #     - foo.example.com
      #     - bar.example.com
    #
    # -- One can apply Middlewares on an entrypoint
    # https://doc.traefik.io/traefik/middlewares/overview/
    # https://doc.traefik.io/traefik/routing/entrypoints/#middlewares
    # -- /!\ It introduces here a link between your static configuration and your dynamic configuration /!\
    # It follows the provider naming convention: https://doc.traefik.io/traefik/providers/overview/#provider-namespace
    # middlewares:
    #   - namespace-name1@kubernetescrd
    #   - namespace-name2@kubernetescrd
    middlewares: []
  metrics:
    # -- When using hostNetwork, use another port to avoid conflict with node exporter:
    # https://github.com/prometheus/prometheus/wiki/Default-port-allocations
    port: 9100
    # hostPort: 9100
    # Defines whether the port is exposed if service.type is LoadBalancer or
    # NodePort.
    #
    # -- You may not want to expose the metrics port on production deployments.
    # If you want to access it from outside your cluster,
    # use `kubectl port-forward` or create a secure ingress
    expose:
      default: false
    # -- The exposed port for this service
    exposedPort: 9100
    # -- The port protocol (TCP/UDP)
    protocol: TCP

# -- TLS Options are created as TLSOption CRDs
# https://doc.traefik.io/traefik/https/tls/#tls-options
# When using `labelSelector`, you'll need to set labels on tlsOption accordingly.
# Example:
# tlsOptions:
#   default:
#     labels: {}
#     sniStrict: true
#   custom-options:
#     labels: {}
#     curvePreferences:
#       - CurveP521
#       - CurveP384
tlsOptions: {}

# -- TLS Store are created as TLSStore CRDs. This is useful if you want to set a default certificate
# https://doc.traefik.io/traefik/https/tls/#default-certificate
# Example:
# tlsStore:
#   default:
#     defaultCertificate:
#       secretName: tls-cert
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
  enabled: false
#   minReplicas: 1
#   maxReplicas: 10
#   metrics:
#   - type: Resource
#     resource:
#       name: cpu
#       target:
#         type: Utilization
#         averageUtilization: 60
#   - type: Resource
#     resource:
#       name: memory
#       target:
#         type: Utilization
#         averageUtilization: 60
#   behavior:
#     scaleDown:
#       stabilizationWindowSeconds: 300
#       policies:
#       - type: Pods
#         value: 1
#         periodSeconds: 60

persistence:
  # -- Enable persistence using Persistent Volume Claims
  # ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
  # It can be used to store TLS certificates, see `storage` in certResolvers
  enabled: false
  name: data
  #  existingClaim: ""
  accessMode: ReadWriteOnce
  size: 128Mi
  # storageClass: ""
  # volumeName: ""
  path: /data
  annotations: {}
  # -- Only mount a subpath of the Volume into the pod
  # subPath: ""

# -- Certificates resolvers configuration
certResolvers: {}
#   letsencrypt:
#     # for challenge options cf. https://doc.traefik.io/traefik/https/acme/
#     email: email@example.com
#     dnsChallenge:
#       # also add the provider's required configuration under env
#       # or expand then from secrets/configmaps with envfrom
#       # cf. https://doc.traefik.io/traefik/https/acme/#providers
#       provider: digitalocean
#       # add futher options for the dns challenge as needed
#       # cf. https://doc.traefik.io/traefik/https/acme/#dnschallenge
#       delayBeforeCheck: 30
#       resolvers:
#         - 1.1.1.1
#         - 8.8.8.8
#     tlsChallenge: true
#     httpChallenge:
#       entryPoint: "web"
#     # It has to match the path with a persistent volume
#     storage: /data/acme.json

# -- If hostNetwork is true, runs traefik in the host network namespace
# To prevent unschedulabel pods due to port collisions, if hostNetwork=true
# and replicas>1, a pod anti-affinity is recommended and will be set if the
# affinity is left as default.
hostNetwork: false

# -- Whether Role Based Access Control objects like roles and rolebindings should be created
rbac:
  enabled: true
  # If set to false, installs ClusterRole and ClusterRoleBinding so Traefik can be used across namespaces.
  # If set to true, installs Role and RoleBinding instead of ClusterRole/ClusterRoleBinding. Providers will only watch target namespace.
  # When combined with providers.kubernetesIngress.disableIngressClassLookup: true and Traefik V3, ClusterRole to watch IngressClass is also disabled.
  namespaced: false
  # Enable user-facing roles
  # https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles
  # aggregateTo: [ "admin" ]
  # List of Kubernetes secrets that are accessible for Traefik. If empty, then access is granted to every secret.
  secretResourceNames: []

# -- Enable to create a PodSecurityPolicy and assign it to the Service Account via RoleBinding or ClusterRoleBinding
podSecurityPolicy:
  enabled: false

# -- The service account the pods will use to interact with the Kubernetes API
serviceAccount:
  # If set, an existing service account is used
  # If not set, a service account is created automatically using the fullname template
  name: ""

# -- Additional serviceAccount annotations (e.g. for oidc authentication)
serviceAccountAnnotations: {}

# -- The resources parameter defines CPU and memory requirements and limits for Traefik's containers.
resources: {}
# requests:
#   cpu: "100m"
#   memory: "50Mi"
# limits:
#   cpu: "300m"
#   memory: "150Mi"

# -- This example pod anti-affinity forces the scheduler to put traefik pods
# -- on nodes where no other traefik pods are scheduled.
# It should be used when hostNetwork: true to prevent port conflicts
affinity: {}
#  podAntiAffinity:
#    requiredDuringSchedulingIgnoredDuringExecution:
#      - labelSelector:
#          matchLabels:
#            app.kubernetes.io/name: {template "traefik.name" . }
#            app.kubernetes.io/instance: {{`'{{ .Release.Name }}-{{ .Release.Namespace }}'`}}
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
#        app: { template "traefik.name" . }
#    maxSkew: 1
#    topologyKey: kubernetes.io/hostname
#    whenUnsatisfiable: DoNotSchedule

# -- Pods can have priority.
# -- Priority indicates the importance of a Pod relative to other Pods.
priorityClassName: ""

# -- Set the container security context
# -- To run the container with ports below 1024 this will need to be adjusted to run as root
securityContext:
  capabilities:
    drop: [ALL]
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false

podSecurityContext:
  # /!\ When setting fsGroup, Kubernetes will recursively change ownership and
  # permissions for the contents of each volume to match the fsGroup. This can
  # be an issue when storing sensitive content like TLS Certificates /!\
  # fsGroup: 65532
  # -- Specifies the policy for changing ownership and permissions of volume contents to match the fsGroup.
  fsGroupChangePolicy: "OnRootMismatch"
  # -- The ID of the group for all containers in the pod to run as.
  runAsGroup: 65532
  # -- Specifies whether the containers should run as a non-root user.
  runAsNonRoot: true
  # -- The ID of the user for all containers in the pod to run as.
  runAsUser: 65532

#
# -- Extra objects to deploy (value evaluated as a template)
#
# In some cases, it can avoid the need for additional, extended or adhoc deployments.
# See #595 for more details and traefik/tests/values/extra.yaml for example.
extraObjects: []

# This will override the default Release Namespace for Helm.
# It will not affect optional CRDs such as `ServiceMonitor` and `PrometheusRules`
# namespaceOverride: traefik
#
## -- This will override the default app.kubernetes.io/instance label for all Objects.
# instanceLabelOverride: traefik
{{- end }}

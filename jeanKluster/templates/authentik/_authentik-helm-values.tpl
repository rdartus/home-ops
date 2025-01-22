---
{{- define "helmValues.authentik" }}

{{-  $dbServiceName := printf "%s.%s.svc.cluster.local" .Values.db.appName .Values.db.namespace -}} 

# -- Provide a name in place of `authentik`. Prefer using global.nameOverride if possible
nameOverride: ""
# -- String to fully override `"authentik.fullname"`. Prefer using global.fullnameOverride if possible
fullnameOverride: ""
# -- Override the Kubernetes version, which is used to evaluate certain manifests
kubeVersionOverride: ""


## Globally shared configuration for authentik components.
global:
  # -- Provide a name in place of `authentik`
  nameOverride: ""
  # -- String to fully override `"authentik.fullname"`
  fullnameOverride: ""
  # -- Common labels for all resources.
  additionalLabels: {}
    # app: authentik

  # Number of old deployment ReplicaSets to retain. The rest will be garbage collected.
  revisionHistoryLimit: 3

  # Default image used by all authentik components. For GeoIP configuration, see the geoip values below.
  image:
    # -- If defined, a repository applied to all authentik deployments
    repository: ghcr.io/goauthentik/server
    # -- Overrides the global authentik whose default is the chart appVersion
    tag: ""
    # -- If defined, an image digest applied to all authentik deployments
    digest: ""
    # -- If defined, an imagePullPolicy applied to all authentik deployments
    pullPolicy: IfNotPresent

  # -- Secrets with credentials to pull images from a private registry
  imagePullSecrets: []

  # -- Annotations for all deployed Deployments
  deploymentAnnotations: {}

  # -- Annotations for all deployed pods
  podAnnotations: {}

  # -- Labels for all deployed pods
  podLabels: {}

  # -- Add Prometheus scrape annotations to all metrics services. This can be used as an alternative to the ServiceMonitors.
  addPrometheusAnnotations: false

  # -- Toggle and define pod-level security context.
  # @default -- `{}` (See [values.yaml])
  securityContext: {}
    # runAsUser: 1000
    # runAsGroup: 1000
    # fsGroup: 1000

  # -- Mapping between IP and hostnames that will be injected as entries in the pod's hosts files
  hostAliases: []
    # - ip: 10.20.30.40
    #   hostnames:
    #     - my.hostname

  # -- Default priority class for all components
  priorityClassName: ""

  # -- Default node selector for all components
  nodeSelector: {}

  # -- Default tolerations for all components
  tolerations: []

  # Default affinity preset for all components
  affinity:
    # -- Default pod anti-affinity rules. Either: `none`, `soft` or `hard`
    podAntiAffinity: soft
    # Node affinity rules
    nodeAffinity:
      # -- Default node affinity rules. Either `none`, `soft` or `hard`
      type: hard
      # -- Default match expressions for node affinity
      matchExpressions: []
        # - key: topology.kubernetes.io/zone
        #   operator: In
        #   values:
        #     - zonea
        #     - zoneb

  # -- Default [TopologySpreadConstraints] rules for all components
  ## Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
  topologySpreadConstraints: []
    # - maxSkew: 1
    #   topologyKey: topology.kubernetes.io/zone
    #   whenUnsatisfiable: DoNotSchedule

  # -- Deployment strategy for all deployed Deployments
  deploymentStrategy: {}
    # type: RollingUpdate
    # rollingUpdate:
    #   maxSurge: 25%
    #   maxUnavailable: 25%

  # -- Environment variables to pass to all deployed Deployments. Does not apply to GeoIP
  # See configuration options at https://goauthentik.io/docs/installation/configuration/
  # @default -- `[]` (See [values.yaml])
  env:
    - name: AUTHENTIK_BOOTSTRAP_PASSWORD
      valueFrom:
        secretKeyRef:
          name: default-secret
          key: password
    # - name: AUTHENTIK_BOOTSTRAP_TOKEN
    #   value : ""
    - name: AUTHENTIK_BOOTSTRAP_EMAIL
      valueFrom:
        secretKeyRef:
          name: smtp-secret
          key: gmail_username
    - name: AUTHENTIK_POSTGRESQL__NAME
      value : "authentik"
    - name: AUTHENTIK_POSTGRESQL__HOST
      value : "{{ $dbServiceName }}"
    - name: AUTHENTIK_POSTGRESQL__USER
      valueFrom:
        secretKeyRef:
          name: authentik-db-secret
          key: username
    - name: AUTHENTIK_POSTGRESQL__PASSWORD
      valueFrom:
        secretKeyRef:
          name: authentik-db-secret
          key: password
    - name: AUTHENTIK_EMAIL__HOST
      value : "smtp.gmail.com"
    - name: AUTHENTIK_REDIS__HOST
      value : "redis-master.default.svc.cluster.local"
    - name: AUTHENTIK_REDIS__PORT
      value : "6379"
    # - name: AUTHENTIK_REDIS__USERNAME
    #   valueFrom:
    #     secretKeyRef:
    #       name: authentik-redis-secret
    #       key: password
    - name: AUTHENTIK_REDIS__PASSWORD
      valueFrom:
        secretKeyRef:
          name: authentik-redis-secret
          key: password
    - name: AUTHENTIK_EMAIL__USERNAME
      valueFrom:
        secretKeyRef:
          name: smtp-secret
          key: gmail_username
    - name: AUTHENTIK_EMAIL__PASSWORD
      valueFrom:
        secretKeyRef:
          name: smtp-secret
          key: gmail_password
    - name: AUTHENTIK_EMAIL__PORT
      value : "587"
    - name: AUTHENTIK_EMAIL__USE_TLS
      value : "true"
    - name: AUTHENTIK_EMAIL__TIMEOUT
      value : "10"
    - name: AUTHENTIK_SECRET_KEY
      valueFrom:
        secretKeyRef:
          name: authentik-key-secret
          key: key
  # env: []
    # - name: AUTHENTIK_VAR_NAME
    #   value: VALUE
    # - name: AUTHENTIK_VAR_OTHER
    #   valueFrom:
    #     secretKeyRef:
    #       name: secret-name
    #       key: secret-key
    # - name: AUTHENTIK_VAR_ANOTHER
    #   valueFrom:
    #     configMapKeyRef:
    #       name: config-map-name
    #       key: config-map-key

  # -- envFrom to pass to all deployed Deployments. Does not apply to GeoIP
  # @default -- `[]` (See [values.yaml])
  envFrom: []
    # - configMapRef:
    #     name: config-map-name
    # - secretRef:
    #     name: secret-name

  # -- Additional volumeMounts to all deployed Deployments. Does not apply to GeoIP
  # @default -- `[]` (See [values.yaml])
  volumeMounts: []
    # - name: custom
    #   mountPath: /custom

  # -- Additional volumes to all deployed Deployments.
  # @default -- `[]` (See [values.yaml])
  volumes: []
    # - name: custom
    #   emptyDir: {}


## Authentik configuration
authentik:
  # -- Log level for server and worker
  log_level: debug
  # -- Secret key used for cookie singing and unique user IDs,
  # don't change this after the first install
  secret_key: ""
  events:
    context_processors:
      # -- Path for the GeoIP City database. If the file doesn't exist, GeoIP features are disabled.
      geoip: /geoip/GeoLite2-City.mmdb
      # -- Path for the GeoIP ASN database. If the file doesn't exist, GeoIP features are disabled.
      asn: /geoip/GeoLite2-ASN.mmdb
  email:
    # -- SMTP Server emails are sent from, fully optional
    host: ""
    # -- SMTP server port
    port: 587
    # -- SMTP credentials, when left empty, no authentication will be done
    username: ""
    # -- SMTP credentials, when left empty, no authentication will be done
    password: ""
    # -- Enable either use_tls or use_ssl, they can't be enabled at the same time.
    use_tls: false
    # -- Enable either use_tls or use_ssl, they can't be enabled at the same time.
    use_ssl: false
    # -- Connection timeout
    timeout: 30
    # -- Email from address, can either be in the format "foo@bar.baz" or "authentik <foo@bar.baz>"
    from: ""
  outposts:
    # -- Template used for managed outposts. The following placeholders can be used
    # %(type)s - the type of the outpost
    # %(version)s - version of your authentik install
    # %(build_hash)s - only for beta versions, the build hash of the image
    container_image_base: ghcr.io/goauthentik/%(type)s:%(version)s
  error_reporting:
    # -- This sends anonymous usage-data, stack traces on errors and
    # performance data to sentry.beryju.org, and is fully opt-in
    enabled: false
    # -- This is a string that is sent to sentry with your error reports
    environment: "k8s"
    # -- Send PII (Personally identifiable information) data to sentry
    send_pii: false
  postgresql:
    # -- set the postgresql hostname to talk to
    # if unset and .Values.postgresql.enabled == true, will generate the default
    # @default -- `{{ .Release.Name }}-postgresql`
    host: "{{ .Release.Name }}-postgresql"
    # -- postgresql Database name
    # @default -- `authentik`
    name: "authentik"
    # -- postgresql Username
    # @default -- `authentik`
    user: "authentik"
    password: ""
    port: 5432
  redis:
    # -- set the redis hostname to talk to
    # @default -- `{{ .Release.Name }}-redis-master`
    host: "{{ .Release.Name }}-redis-master"
    password: ""


blueprints:
  # -- List of config maps to mount blueprints from.
  # Only keys in the configMap ending with `.yaml` will be discovered and applied.
  configMaps: []
  # -- List of secrets to mount blueprints from.
  # Only keys in the secret ending with `.yaml` will be discovered and applied.
  secrets: []


## authentik server
server:
  # -- authentik server name
  name: server

  # -- The number of server pods to run
  replicas: 1

  ## authentik server Horizontal Pod Autoscaler
  autoscaling:
    # -- Enable Horizontal Pod Autoscaler ([HPA]) for the authentik server
    enabled: false
    # -- Minimum number of replicas for the authentik server [HPA]
    minReplicas: 1
    # -- Maximum number of replicas for the authentik server [HPA]
    maxReplicas: 5
    # -- Average CPU utilization percentage for the authentik server [HPA]
    targetCPUUtilizationPercentage: 50
    # -- Average memory utilization percentage for the authentik server [HPA]
    targetMemoryUtilizationPercentage: ~
    # -- Configures the scaling behavior of the target in both Up and Down directions.
    behavior: {}
      # scaleDown:
      #   stabilizationWindowSeconds: 300
      #   policies:
      #     - type: Pods
      #       value: 1
      #       periodSeconds: 180
      # scaleUp:
      #   stabilizationWindowSeconds: 300
      #   policies:
      #     - type: Pods
      #       value: 2
      #       periodSeconds: 60
    # -- Configures custom HPA metrics for the authentik server
    # Ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
    metrics: []

  ## authentik server Pod Disruption Budget
  ## Ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
  pdb:
    # -- Deploy a [PodDistrubtionBudget] for the authentik server
    enabled: false
    # -- Labels to be added to the authentik server pdb
    labels: {}
    # -- Annotations to be added to the authentik server pdb
    annotations: {}
    # -- Number of pods that are available after eviction as number or percentage (eg.: 50%)
    # @default -- `""` (defaults to 0 if not specified)
    minAvailable: ""
    # -- Number of pods that are unavailable after eviction as number or percentage (eg.: 50%)
    ## Has higher precedence over `server.pdb.minAvailable`
    maxUnavailable: ""

  ## authentik server image
  ## This should match what is deployed in the worker. Prefer using global.image
  image:
    # -- Repository to use to the authentik server
    # @default -- `""` (defaults to global.image.repository)
    repository: "" # defaults to global.image.repository
    # -- Tag to use to the authentik server
    # @default -- `""` (defaults to global.image.tag)
    tag: "" # defaults to global.image.tag
    # -- Digest to use to the authentik server
    # @default -- `""` (defaults to global.image.digest)
    digest: "" # defaults to global.image.digest
    # -- Image pull policy to use to the authentik server
    # @default -- `""` (defaults to global.image.pullPolicy)
    pullPolicy: "" # defaults to global.image.pullPolicy

  # -- Secrets with credentials to pull images from a private registry
  # @default -- `[]` (defaults to global.imagePullSecrets)
  imagePullSecrets: []

  # -- Environment variables to pass to the authentik server. Does not apply to GeoIP
  # See configuration options at https://goauthentik.io/docs/installation/configuration/
  # @default -- `[]` (See [values.yaml])
  env: []
    # - name: AUTHENTIK_VAR_NAME
    #   value: VALUE
    # - name: AUTHENTIK_VAR_OTHER
    #   valueFrom:
    #     secretKeyRef:
    #       name: secret-name
    #       key: secret-key
    # - name: AUTHENTIK_VAR_ANOTHER
    #   valueFrom:
    #     configMapKeyRef:
    #       name: config-map-name
    #       key: config-map-key

  # -- envFrom to pass to the authentik server. Does not apply to GeoIP
  # @default -- `[]` (See [values.yaml])
  envFrom: []
    # - configMapRef:
    #     name: config-map-name
    # - secretRef:
    #     name: secret-name

  # -- Specify postStart and preStop lifecycle hooks for you authentik server container
  lifecycle: {}

  # -- Additional containers to be added to the authentik server pod
  ## Note: Supports use of custom Helm templates
  extraContainers: []
  # - name: my-sidecar
  #   image: nginx:latest

  # -- Init containers to add to the authentik server pod
  ## Note: Supports use of custom Helm templates
  initContainers: []
  # - name: download-tools
  #   image: alpine:3
  #   command: [sh, -c]
  #   args:
  #     - echo init

  # -- Additional volumeMounts to the authentik server main container
  volumeMounts: []
    # - name: custom
    #   mountPath: /custom

  # -- Additional volumes to the authentik server pod
  volumes: []
    # - name: custom
    #   emptyDir: {}

  # -- Annotations to be added to the authentik server Deployment
  deploymentAnnotations: {}

  # -- Annotations to be added to the authentik server pods
  podAnnotations: {}

  # -- Labels to be added to the authentik server pods
  podLabels: {}

  # -- Resource limits and requests for the authentik server
  resources: {}
    # requests:
    #   cpu: 100m
    #   memory: 512Mi
    # limits:
    #   memory: 512Mi

  # authentik server container ports
  containerPorts:
    # -- http container port
    http: 9000
    # -- https container port
    https: 9443
    # -- metrics container port
    metrics: 9300

  # -- Host Network for authentik server pods
  hostNetwork: false

  # -- [DNS configuration]
  dnsConfig: {}
  # -- Alternative DNS policy for authentik server pods
  dnsPolicy: ""

  # -- authentik server pod-level security context
  # @default -- `{}` (See [values.yaml])
  securityContext: {}
    # runAsUser: 1000
    # runAsGroup: 1000
    # fsGroup: 1000

  # -- authentik server container-level security context
  # @default -- See [values.yaml]
  containerSecurityContext: {}
    # Not all of the following has been tested. Use at your own risk.
    # runAsNonRoot: true
    # readOnlyRootFilesystem: true
    # allowPrivilegeEscalation: false
    # seccomProfile:
    #   type: RuntimeDefault
    # capabilities:
    #   drop:
    #     - ALL

  ## Liveness, readiness and startup probes for authentik server
  ## Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/
  livenessProbe:
    # -- Minimum consecutive failures for the [probe] to be considered failed after having succeeded
    failureThreshold: 3
    # -- Number of seconds after the container has started before [probe] is initiated
    initialDelaySeconds: 5
    # -- How often (in seconds) to perform the [probe]
    periodSeconds: 10
    # -- Minimum consecutive successes for the [probe] to be considered successful after having failed
    successThreshold: 1
    # -- Number of seconds after which the [probe] times out
    timeoutSeconds: 1
    ## Probe configuration
    httpGet:
      path: /-/health/live/
      port: http

  readinessProbe:
    # -- Minimum consecutive failures for the [probe] to be considered failed after having succeeded
    failureThreshold: 3
    # -- Number of seconds after the container has started before [probe] is initiated
    initialDelaySeconds: 5
    # -- How often (in seconds) to perform the [probe]
    periodSeconds: 10
    # -- Minimum consecutive successes for the [probe] to be considered successful after having failed
    successThreshold: 1
    # -- Number of seconds after which the [probe] times out
    timeoutSeconds: 1
    ## Probe configuration
    httpGet:
      path: /-/health/ready/
      port: http

  startupProbe:
    # -- Minimum consecutive failures for the [probe] to be considered failed after having succeeded
    failureThreshold: 60
    # -- Number of seconds after the container has started before [probe] is initiated
    initialDelaySeconds: 5
    # -- How often (in seconds) to perform the [probe]
    periodSeconds: 10
    # -- Minimum consecutive successes for the [probe] to be considered successful after having failed
    successThreshold: 1
    # -- Number of seconds after which the [probe] times out
    timeoutSeconds: 1
    ## Probe configuration
    httpGet:
      path: /-/health/live/
      port: http

  # -- terminationGracePeriodSeconds for container lifecycle hook
  terminationGracePeriodSeconds: 30

  # -- Prority class for the authentik server pods
  # @default -- `""` (defaults to global.priorityClassName)
  priorityClassName: ""

  # -- [Node selector]
  # @default -- `{}` (defaults to global.nodeSelector)
  nodeSelector: {}

  # -- [Tolerations] for use with node taints
  # @default -- `[]` (defaults to global.tolerations)
  tolerations: []

  # -- Assign custom [affinity] rules to the deployment
  # @default -- `{}` (defaults to the global.affinity preset)
  affinity: {}

  # -- Assign custom [TopologySpreadConstraints] rules to the authentik server
  # @default -- `[]` (defaults to global.topologySpreadConstraints)
  ## Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
  ## If labelSelector is left out, it will default to the labelSelector configuration of the deployment
  topologySpreadConstraints: []
    # - maxSkew: 1
    #   topologyKey: topology.kubernetes.io/zone
    #   whenUnsatisfiable: DoNotSchedule

  # -- Deployment strategy to be added to the authentik server Deployment
  # @default -- `{}` (defaults to global.deploymentStrategy)
  deploymentStrategy: {}
    # type: RollingUpdate
    # rollingUpdate:
    #   maxSurge: 25%
    #   maxUnavailable: 25%

  ## authentik server service configuration
  service:
    # -- authentik server service annotations
    annotations: {}
    # -- authentik server service labels
    labels: {}
    # -- authentik server service type
    type: ClusterIP
    # -- authentik server service http port for NodePort service type (only if `server.service.type` is set to `NodePort`)
    nodePortHttp: 30080
    # -- authentik server service https port for NodePort service type (only if `server.service.type` is set to `NodePort`)
    nodePortHttps: 30443
    # -- authentik server service http port
    servicePortHttp: 80
    # -- authentik server service https port
    servicePortHttps: 443
    # -- authentik server service http port name
    servicePortHttpName: http
    # -- authentik server service https port name
    servicePortHttpsName: https
    # -- authentik server service http port appProtocol
    # servicePortHttpAppProtocol: HTTP
    # -- authentik server service https port appProtocol
    # servicePortHttpsAppProtocol: HTTPS
    # -- LoadBalancer will get created with the IP specified in this field
    loadBalancerIP: ""
    # -- Source IP ranges to allow access to service from
    loadBalancerSourceRanges: []
    # -- authentik server service external IPs
    externalIPs: []
    # -- Denotes if this service desires to route external traffic to node-local or cluster-wide endpoints
    externalTrafficPolicy: ""
    # -- Used to maintain session affinity. Supports `ClientIP` and `None`
    sessionAffinity: ""
    # -- Session affinity configuration
    sessionAffinityConfig: {}

  ## authentik server metrics service configuration
  metrics:
    # -- deploy metrics service
    enabled: false
    service:
      # -- metrics service type
      type: ClusterIP
      # -- metrics service clusterIP. `None` makes a "headless service" (no virtual IP)
      clusterIP: ""
      # -- metrics service annotations
      annotations: {}
      # -- metrics service labels
      labels: {}
      # -- metrics service port
      servicePort: 9300
      # -- metrics service port name
      portName: metrics
    serviceMonitor:
      # -- enable a prometheus ServiceMonitor
      enabled: false
      # -- Prometheus ServiceMonitor interval
      interval: 30s
      # -- Prometheus ServiceMonitor scrape timeout
      scrapeTimeout: 3s
      # -- Prometheus [RelabelConfigs] to apply to samples before scraping
      relabelings: []
      # -- Prometheus [MetricsRelabelConfigs] to apply to samples before ingestion
      metricRelabelings: []
      # -- Prometheus ServiceMonitor selector
      selector: {}
        # prometheus: kube-prometheus

      # -- Prometheus ServiceMonitor scheme
      scheme: ""
      # -- Prometheus ServiceMonitor tlsConfig
      tlsConfig: {}
      # -- Prometheus ServiceMonitor namespace
      namespace: ""
      # -- Prometheus ServiceMonitor labels
      labels: {}
      # -- Prometheus ServiceMonitor annotations
      annotations: {}

  ingress:
    # -- enable an ingress resource for the authentik server
    enabled: true
    # -- additional ingress annotations
    annotations: 
      hajimari.io/enable: "true"
      hajimari.io/group: "Management"
      hajimari.io/icon: "safe-square"
      cert-manager.io/cluster-issuer: zerossl
    # -- additional ingress labels
    labels: {}
    # -- defines which ingress controller will implement the resource
    ingressClassName: traefik-ingresses
    # -- List of ingress hosts
    hosts: 
      - authentik.dartus.fr
      # - authentik.domain.tld

    # -- List of ingress paths
    paths:
      - /
    # -- Ingress path type. One of `Exact`, `Prefix` or `ImplementationSpecific`
    pathType: Prefix
    # -- additional ingress paths
    extraPaths: []
      # - path: /*
      #   pathType: Prefix
      #   backend:
      #     service:
      #       name: ssl-redirect
      #       port:
      #         name: use-annotation

    # -- ingress TLS configuration
    tls:
      - hosts:
        - authentik.dartus.fr
        secretName: authentik.dartus.fr-tls

      # - secretName: authentik-tls
      #   hosts:
      #     - authentik.domain.tld

    # -- uses `server.service.servicePortHttps` instead of `server.service.servicePortHttp`
    https: false


## authentik worker
worker:
  # -- authentik worker name
  name: worker

  # -- The number of worker pods to run
  replicas: 1

  ## authentik worker Horizontal Pod Autoscaler
  autoscaling:
    # -- Enable Horizontal Pod Autoscaler ([HPA]) for the authentik worker
    enabled: false
    # -- Minimum number of replicas for the authentik worker [HPA]
    minReplicas: 1
    # -- Maximum number of replicas for the authentik worker [HPA]
    maxReplicas: 5
    # -- Average CPU utilization percentage for the authentik worker [HPA]
    targetCPUUtilizationPercentage: 50
    # -- Average memory utilization percentage for the authentik worker [HPA]
    targetMemoryUtilizationPercentage: ~
    # -- Configures the scaling behavior of the target in both Up and Down directions.
    behavior: {}
      # scaleDown:
      #   stabilizationWindowSeconds: 300
      #   policies:
      #     - type: Pods
      #       value: 1
      #       periodSeconds: 180
      # scaleUp:
      #   stabilizationWindowSeconds: 300
      #   policies:
      #     - type: Pods
      #       value: 2
      #       periodSeconds: 60
    # -- Configures custom HPA metrics for the authentik worker
    # Ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
    metrics: []

  ## authentik worker Pod Disruption Budget
  ## Ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
  pdb:
    # -- Deploy a [PodDistrubtionBudget] for the authentik worker
    enabled: false
    # -- Labels to be added to the authentik worker pdb
    labels: {}
    # -- Annotations to be added to the authentik worker pdb
    annotations: {}
    # -- Number of pods that are available after eviction as number or percentage (eg.: 50%)
    # @default -- `""` (defaults to 0 if not specified)
    minAvailable: ""
    # -- Number of pods that are unavailable after eviction as number or percentage (eg.: 50%)
    ## Has higher precedence over `worker.pdb.minAvailable`
    maxUnavailable: ""

  ## authentik worker image
  ## This should match what is deployed in the server. Prefer using global.image
  image:
    # -- Repository to use to the authentik worker
    # @default -- `""` (defaults to global.image.repository)
    repository: "" # defaults to global.image.repository
    # -- Tag to use to the authentik worker
    # @default -- `""` (defaults to global.image.tag)
    tag: "" # defaults to global.image.tag
    # -- Digest to use to the authentik worker
    # @default -- `""` (defaults to global.image.digest)
    digest: "" # defaults to global.image.digest
    # -- Image pull policy to use to the authentik worker
    # @default -- `""` (defaults to global.image.pullPolicy)
    pullPolicy: "" # defaults to global.image.pullPolicy

  # -- Secrets with credentials to pull images from a private registry
  # @default -- `[]` (defaults to global.imagePullSecrets)
  imagePullSecrets: []

  # -- Environment variables to pass to the authentik worker. Does not apply to GeoIP
  # See configuration options at https://goauthentik.io/docs/installation/configuration/
  # @default -- `[]` (See [values.yaml])
  env: []
    # - name: AUTHENTIK_VAR_NAME
    #   value: VALUE
    # - name: AUTHENTIK_VAR_OTHER
    #   valueFrom:
    #     secretKeyRef:
    #       name: secret-name
    #       key: secret-key
    # - name: AUTHENTIK_VAR_ANOTHER
    #   valueFrom:
    #     configMapKeyRef:
    #       name: config-map-name
    #       key: config-map-key

  # -- envFrom to pass to the authentik worker. Does not apply to GeoIP
  # @default -- `[]` (See [values.yaml])
  envFrom: []
    # - configMapRef:
    #     name: config-map-name
    # - secretRef:
    #     name: secret-name

  # -- Specify postStart and preStop lifecycle hooks for you authentik worker container
  lifecycle: {}

  # -- Additional containers to be added to the authentik worker pod
  ## Note: Supports use of custom Helm templates
  extraContainers: []
  # - name: my-sidecar
  #   image: nginx:latest

  # -- Init containers to add to the authentik worker pod
  ## Note: Supports use of custom Helm templates
  initContainers: []
  # - name: download-tools
  #   image: alpine:3
  #   command: [sh, -c]
  #   args:
  #     - echo init

  # -- Additional volumeMounts to the authentik worker main container
  volumeMounts: []
    # - name: custom
    #   mountPath: /custom

  # -- Additional volumes to the authentik worker pod
  volumes: []
    # - name: custom
    #   emptyDir: {}

  # -- Annotations to be added to the authentik worker Deployment
  deploymentAnnotations: {}

  # -- Annotations to be added to the authentik worker pods
  podAnnotations: {}

  # -- Labels to be added to the authentik worker pods
  podLabels: {}

  # -- Resource limits and requests for the authentik worker
  resources: {}
    # requests:
    #   cpu: 100m
    #   memory: 512Mi
    # limits:
    #   memory: 512Mi

  # -- Host Network for authentik worker pods
  hostNetwork: false

  # -- [DNS configuration]
  dnsConfig: {}
  # -- Alternative DNS policy for authentik worker pods
  dnsPolicy: ""

  # -- authentik worker pod-level security context
  # @default -- `{}` (See [values.yaml])
  securityContext: {}
    # runAsUser: 1000
    # runAsGroup: 1000
    # fsGroup: 1000

  # -- authentik worker container-level security context
  # @default -- See [values.yaml]
  containerSecurityContext: {}
    # Not all of the following has been tested. Use at your own risk.
    # runAsNonRoot: true
    # readOnlyRootFilesystem: true
    # allowPrivilegeEscalation: false
    # seccomProfile:
    #   type: RuntimeDefault
    # capabilities:
    #   drop:
    #     - ALL

  livenessProbe:
    # -- Minimum consecutive failures for the [probe] to be considered failed after having succeeded
    failureThreshold: 3
    # -- Number of seconds after the container has started before [probe] is initiated
    initialDelaySeconds: 5
    # -- How often (in seconds) to perform the [probe]
    periodSeconds: 10
    # -- Minimum consecutive successes for the [probe] to be considered successful after having failed
    successThreshold: 1
    # -- Number of seconds after which the [probe] times out
    timeoutSeconds: 1
    ## Probe configuration
    exec:
      command:
        - ak
        - healthcheck

  readinessProbe:
    # -- Minimum consecutive failures for the [probe] to be considered failed after having succeeded
    failureThreshold: 3
    # -- Number of seconds after the container has started before [probe] is initiated
    initialDelaySeconds: 5
    # -- How often (in seconds) to perform the [probe]
    periodSeconds: 10
    # -- Minimum consecutive successes for the [probe] to be considered successful after having failed
    successThreshold: 1
    # -- Number of seconds after which the [probe] times out
    timeoutSeconds: 1
    ## Probe configuration
    exec:
      command:
        - ak
        - healthcheck

  startupProbe:
    # -- Minimum consecutive failures for the [probe] to be considered failed after having succeeded
    failureThreshold: 60
    # -- Number of seconds after the container has started before [probe] is initiated
    initialDelaySeconds: 30
    # -- How often (in seconds) to perform the [probe]
    periodSeconds: 10
    # -- Minimum consecutive successes for the [probe] to be considered successful after having failed
    successThreshold: 1
    # -- Number of seconds after which the [probe] times out
    timeoutSeconds: 1
    ## Probe configuration
    exec:
      command:
        - ak
        - healthcheck

  # -- terminationGracePeriodSeconds for container lifecycle hook
  terminationGracePeriodSeconds: 30

  # -- Prority class for the authentik worker pods
  # @default -- `""` (defaults to global.priorityClassName)
  priorityClassName: ""

  # -- [Node selector]
  # @default -- `{}` (defaults to global.nodeSelector)
  nodeSelector: {}

  # -- [Tolerations] for use with node taints
  # @default -- `[]` (defaults to global.tolerations)
  tolerations: []

  # -- Assign custom [affinity] rules to the deployment
  # @default -- `{}` (defaults to the global.affinity preset)
  affinity: {}

  # -- Assign custom [TopologySpreadConstraints] rules to the authentik worker
  # @default -- `[]` (defaults to global.topologySpreadConstraints)
  ## Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
  ## If labelSelector is left out, it will default to the labelSelector configuration of the deployment
  topologySpreadConstraints: []
    # - maxSkew: 1
    #   topologyKey: topology.kubernetes.io/zone
    #   whenUnsatisfiable: DoNotSchedule

  # -- Deployment strategy to be added to the authentik worker Deployment
  # @default -- `{}` (defaults to global.deploymentStrategy)
  deploymentStrategy: {}
    # type: RollingUpdate
    # rollingUpdate:
    #   maxSurge: 25%
    #   maxUnavailable: 25%


serviceAccount:
  # -- Create service account. Needed for managed outposts
  create: true
  # -- additional service account annotations
  annotations: {}
  serviceAccountSecret:
    # As we use the authentik-remote-cluster chart as subchart, and that chart
    # creates a service account secret by default which we don't need here,
    # disable its creation
    enabled: false
  fullnameOverride: authentik


geoip:
  # -- enable GeoIP sidecars for the authentik server and worker pods
  enabled: false

  editionIds: "GeoLite2-City GeoLite2-ASN"
  # -- GeoIP update frequency, in hours
  updateInterval: 8
  # -- sign up under https://www.maxmind.com/en/geolite2/signup
  accountId: ""
  # -- sign up under https://www.maxmind.com/en/geolite2/signup
  licenseKey: ""
  ## use existing secret instead of values above
  existingSecret:
    # -- name of an existing secret to use instead of values above
    secretName: ""
    # -- key in the secret containing the account ID
    accountId: "account_id"
    # -- key in the secret containing the license key
    licenseKey: "license_key"

  image:
    # -- If defined, a repository for GeoIP images
    repository: ghcr.io/maxmind/geoipupdate
    # -- If defined, a tag for GeoIP images
    tag: v6.0.0
    # -- If defined, an image digest for GeoIP images
    digest: ""
    # -- If defined, an imagePullPolicy for GeoIP images
    pullPolicy: IfNotPresent

  # -- Environment variables to pass to the GeoIP containers
  # @default -- `[]` (See [values.yaml])
  env: []
    # - name: GEOIPUPDATE_VAR_NAME
    #   value: VALUE
    # - name: GEOIPUPDATE_VAR_OTHER
    #   valueFrom:
    #     secretKeyRef:
    #       name: secret-name
    #       key: secret-key
    # - name: GEOIPUPDATE_VAR_ANOTHER
    #   valueFrom:
    #     configMapKeyRef:
    #       name: config-map-name
    #       key: config-map-key

  # -- envFrom to pass to the GeoIP containers
  # @default -- `[]` (See [values.yaml])
  envFrom: []
    # - configMapRef:
    #     name: config-map-name
    # - secretRef:
    #     name: secret-name

  # -- Additional volumeMounts to the GeoIP containers. Make sure the volumes exists for the server and the worker.
  volumeMounts: []
    # - name: custom
    #   mountPath: /custom

  # -- Resource limits and requests for GeoIP containers
  resources: {}
    # requests:
    #   cpu: 100m
    #   memory: 128Mi
    # limits:
    #   memory: 128Mi

  # -- GeoIP container-level security context
  # @default -- See [values.yaml]
  containerSecurityContext: {}
    # Not all of the following has been tested. Use at your own risk.
    # runAsNonRoot: true
    # readOnlyRootFilesystem: true
    # allowPrivilegeEscalation: false
    # seccomProfile:
    #   type: RuntimeDefault
    # capabilities:
    #   drop:
    #     - ALL


prometheus:
  rules:
    enabled: false
    # -- PrometheusRule namespace
    namespace: ""
    # -- PrometheusRule selector
    selector: {}
      # prometheus: kube-prometheus

    # -- PrometheusRule labels
    labels: {}
    # -- PrometheusRule annotations
    annotations: {}


postgresql:
  # -- enable the Bitnami PostgreSQL chart. Refer to https://github.com/bitnami/charts/blob/main/bitnami/postgresql/ for possible values.
  enabled: false
  auth:
    username: authentik
    database: authentik
    # password: ""
  primary:
    extendedConfiguration: |
      max_connections = 500
    # persistence:
    #   enabled: true
    #   storageClass:
    #   accessModes:
    #     - ReadWriteOnce


redis:
  # -- enable the Bitnami Redis chart. Refer to https://github.com/bitnami/charts/blob/main/bitnami/redis/ for possible values.
  enabled: false
  architecture: standalone
  auth:
    enabled: false

  image:
    tag: 6.2.10-debian-11-r13
    
# -- additional resources to deploy. Those objects are templated.
additionalObjects: []
{{- end }}
{{- define "helmValues.vault" }}

# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Available parameters and their default values for the Vault chart.

global:
  # enabled is the master enabled switch. Setting this to true or false
  # will enable or disable all the components within this chart by default.
  enabled: true

  # The namespace to deploy to. Defaults to the `helm` installation namespace.
  namespace: ""

  # Image pull secret to use for registry authentication.
  # Alternatively, the value may be specified as an array of strings.
  imagePullSecrets: []
  # imagePullSecrets:
  #   - name: image-pull-secret

  # TLS for end-to-end encrypted transport
  tlsDisable: true

  # External vault server address for the injector and CSI provider to use.
  # Setting this will disable deployment of a vault server.
  externalVaultAddr: ""

  # If deploying to OpenShift
  openshift: false

  # Create PodSecurityPolicy for pods
  psp:
    enable: false
    # Annotation for PodSecurityPolicy.
    # This is a multi-line templated string map, and can also be set as YAML.
    annotations: |
      seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default,runtime/default
      apparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default
      seccomp.security.alpha.kubernetes.io/defaultProfileName:  runtime/default
      apparmor.security.beta.kubernetes.io/defaultProfileName:  runtime/default

  serverTelemetry:
    # Enable integration with the Prometheus Operator
    # See the top level serverTelemetry section below before enabling this feature.
    prometheusOperator: false

injector:
  # True if you want to enable vault agent injection.
  # @default: global.enabled
  enabled: "-"

  replicas: 1

  # Configures the port the injector should listen on
  port: 8080

  # If multiple replicas are specified, by default a leader will be determined
  # so that only one injector attempts to create TLS certificates.
  leaderElector:
    enabled: true

  # If true, will enable a node exporter metrics endpoint at /metrics.
  metrics:
    enabled: false

  # Deprecated: Please use global.externalVaultAddr instead.
  externalVaultAddr: ""

  # image sets the repo and tag of the vault-k8s image to use for the injector.
  image:
    repository: "hashicorp/vault-k8s"
    tag: "1.5.0"
    pullPolicy: IfNotPresent

  # agentImage sets the repo and tag of the Vault image to use for the Vault Agent
  # containers.  This should be set to the official Vault image.  Vault 1.3.1+ is
  # required.
  agentImage:
    repository: "hashicorp/vault"
    tag: "1.18.1"

  # The default values for the injected Vault Agent containers.
  agentDefaults:
    # For more information on configuring resources, see the K8s documentation:
    # https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
    cpuLimit: "500m"
    cpuRequest: "250m"
    memLimit: "128Mi"
    memRequest: "64Mi"
    # ephemeralLimit: "128Mi"
    # ephemeralRequest: "64Mi"

    # Default template type for secrets when no custom template is specified.
    # Possible values include: "json" and "map".
    template: "map"

    # Default values within Agent's template_config stanza.
    templateConfig:
      exitOnRetryFailure: true
      staticSecretRenderInterval: ""

  # Used to define custom livenessProbe settings
  livenessProbe:
    # When a probe fails, Kubernetes will try failureThreshold times before giving up
    failureThreshold: 2
    # Number of seconds after the container has started before probe initiates
    initialDelaySeconds: 5
    # How often (in seconds) to perform the probe
    periodSeconds: 2
    # Minimum consecutive successes for the probe to be considered successful after having failed
    successThreshold: 1
    # Number of seconds after which the probe times out.
    timeoutSeconds: 5
  # Used to define custom readinessProbe settings
  readinessProbe:
    # When a probe fails, Kubernetes will try failureThreshold times before giving up
    failureThreshold: 2
    # Number of seconds after the container has started before probe initiates
    initialDelaySeconds: 5
    # How often (in seconds) to perform the probe
    periodSeconds: 2
    # Minimum consecutive successes for the probe to be considered successful after having failed
    successThreshold: 1
    # Number of seconds after which the probe times out.
    timeoutSeconds: 5
  # Used to define custom startupProbe settings
  startupProbe:
    # When a probe fails, Kubernetes will try failureThreshold times before giving up
    failureThreshold: 12
    # Number of seconds after the container has started before probe initiates
    initialDelaySeconds: 5
    # How often (in seconds) to perform the probe
    periodSeconds: 5
    # Minimum consecutive successes for the probe to be considered successful after having failed
    successThreshold: 1
    # Number of seconds after which the probe times out.
    timeoutSeconds: 5

  # Mount Path of the Vault Kubernetes Auth Method.
  authPath: "auth/kubernetes"

  # Configures the log verbosity of the injector.
  # Supported log levels include: trace, debug, info, warn, error
  logLevel: "info"

  # Configures the log format of the injector. Supported log formats: "standard", "json".
  logFormat: "standard"

  # Configures all Vault Agent sidecars to revoke their token when shutting down
  revokeOnShutdown: false

  webhook:
    # Configures failurePolicy of the webhook. The "unspecified" default behaviour depends on the
    # API Version of the WebHook.
    # To block pod creation while the webhook is unavailable, set the policy to `Fail` below.
    # See https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#failure-policy
    #
    failurePolicy: Ignore

    # matchPolicy specifies the approach to accepting changes based on the rules of
    # the MutatingWebhookConfiguration.
    # See https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#matching-requests-matchpolicy
    # for more details.
    #
    matchPolicy: Exact

    # timeoutSeconds is the amount of seconds before the webhook request will be ignored
    # or fails.
    # If it is ignored or fails depends on the failurePolicy
    # See https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#timeouts
    # for more details.
    #
    timeoutSeconds: 30

    # namespaceSelector is the selector for restricting the webhook to only
    # specific namespaces.
    # See https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#matching-requests-namespaceselector
    # for more details.
    # Example:
    # namespaceSelector:
    #    matchLabels:
    #      sidecar-injector: enabled
    namespaceSelector: {}

    # objectSelector is the selector for restricting the webhook to only
    # specific labels.
    # See https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#matching-requests-objectselector
    # for more details.
    # Example:
    # objectSelector:
    #    matchLabels:
    #      vault-sidecar-injector: enabled
    objectSelector: |
      matchExpressions:
      - key: app.kubernetes.io/name
        operator: NotIn
        values:
        - vault-agent-injector

    # Extra annotations to attach to the webhook
    annotations: {}

  # Deprecated: please use 'webhook.failurePolicy' instead
  # Configures failurePolicy of the webhook. The "unspecified" default behaviour depends on the
  # API Version of the WebHook.
  # To block pod creation while webhook is unavailable, set the policy to `Fail` below.
  # See https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#failure-policy
  #
  failurePolicy: Ignore

  # Deprecated: please use 'webhook.namespaceSelector' instead
  # namespaceSelector is the selector for restricting the webhook to only
  # specific namespaces.
  # See https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#matching-requests-namespaceselector
  # for more details.
  # Example:
  # namespaceSelector:
  #    matchLabels:
  #      sidecar-injector: enabled
  namespaceSelector: {}

  # Deprecated: please use 'webhook.objectSelector' instead
  # objectSelector is the selector for restricting the webhook to only
  # specific labels.
  # See https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#matching-requests-objectselector
  # for more details.
  # Example:
  # objectSelector:
  #    matchLabels:
  #      vault-sidecar-injector: enabled
  objectSelector: {}

  # Deprecated: please use 'webhook.annotations' instead
  # Extra annotations to attach to the webhook
  webhookAnnotations: {}

  certs:
    # secretName is the name of the secret that has the TLS certificate and
    # private key to serve the injector webhook. If this is null, then the
    # injector will default to its automatic management mode that will assign
    # a service account to the injector to generate its own certificates.
    secretName: null

    # caBundle is a base64-encoded PEM-encoded certificate bundle for the CA
    # that signed the TLS certificate that the webhook serves. This must be set
    # if secretName is non-null unless an external service like cert-manager is
    # keeping the caBundle updated.
    caBundle: ""

    # certName and keyName are the names of the files within the secret for
    # the TLS cert and private key, respectively. These have reasonable
    # defaults but can be customized if necessary.
    certName: tls.crt
    keyName: tls.key

  # Security context for the pod template and the injector container
  # The default pod securityContext is:
  #   runAsNonRoot: true
  # and for container is
  #    allowPrivilegeEscalation: false
  #    capabilities:
  #      drop:
  #        - ALL
  securityContext:
    pod: {}
    container: {}

  resources: {}
  # resources:
  #   requests:
  #     memory: 256Mi
  #     cpu: 250m
  #   limits:
  #     memory: 256Mi
  #     cpu: 250m

  # extraEnvironmentVars is a list of extra environment variables to set in the
  # injector deployment.
  extraEnvironmentVars: {}
    # KUBERNETES_SERVICE_HOST: kubernetes.default.svc

  # Affinity Settings for injector pods
  # This can either be a multi-line string or YAML matching the PodSpec's affinity field.
  # Commenting out or setting as empty the affinity variable, will allow
  # deployment of multiple replicas to single node services such as Minikube.
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app.kubernetes.io/name: vault-agent-injector
              app.kubernetes.io/instance: "{{ .Release.Name }}"
              component: webhook
          topologyKey: kubernetes.io/hostname

  # Topology settings for injector pods
  # ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
  # This should be either a multi-line string or YAML matching the topologySpreadConstraints array
  # in a PodSpec.
  topologySpreadConstraints: []

  # Toleration Settings for injector pods
  # This should be either a multi-line string or YAML matching the Toleration array
  # in a PodSpec.
  tolerations: []

  # nodeSelector labels for server pod assignment, formatted as a multi-line string or YAML map.
  # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector
  # Example:
  # nodeSelector:
  #   beta.kubernetes.io/arch: amd64
  nodeSelector: {}

  # Priority class for injector pods
  priorityClassName: ""

  # Extra annotations to attach to the injector pods
  # This can either be YAML or a YAML-formatted multi-line templated string map
  # of the annotations to apply to the injector pods
  annotations: {}

  # Extra labels to attach to the agent-injector
  # This should be a YAML map of the labels to apply to the injector
  extraLabels: {}

  # Should the injector pods run on the host network (useful when using
  # an alternate CNI in EKS)
  hostNetwork: false

  # Injector service specific config
  service:
    # Extra annotations to attach to the injector service
    annotations: {}

  # Injector serviceAccount specific config
  serviceAccount:
    # Extra annotations to attach to the injector serviceAccount
    annotations: {}

  # A disruption budget limits the number of pods of a replicated application
  # that are down simultaneously from voluntary disruptions
  podDisruptionBudget: {}
  # podDisruptionBudget:
  #   maxUnavailable: 1

  # strategy for updating the deployment. This can be a multi-line string or a
  # YAML map.
  strategy: {}
  # strategy: |
  #   rollingUpdate:
  #     maxSurge: 25%
  #     maxUnavailable: 25%
  #   type: RollingUpdate

server:
  # If true, or "-" with global.enabled true, Vault server will be installed.
  # See vault.mode in _helpers.tpl for implementation details.
  enabled: "-"

  # [Enterprise Only] This value refers to a Kubernetes secret that you have
  # created that contains your enterprise license. If you are not using an
  # enterprise image or if you plan to introduce the license key via another
  # route, then leave secretName blank ("") or set it to null.
  # Requires Vault Enterprise 1.8 or later.
  enterpriseLicense:
    # The name of the Kubernetes secret that holds the enterprise license. The
    # secret must be in the same namespace that Vault is installed into.
    secretName: ""
    # The key within the Kubernetes secret that holds the enterprise license.
    secretKey: "license"

  # Resource requests, limits, etc. for the server cluster placement. This
  # should map directly to the value of the resources field for a PodSpec.
  # By default no direct resource request is made.

  image:
    repository: "hashicorp/vault"
    tag: "1.18.1"
    # Overrides the default Image Pull Policy
    pullPolicy: IfNotPresent

  # Configure the Update Strategy Type for the StatefulSet
  # See https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies
  updateStrategyType: "OnDelete"

  # Configure the logging verbosity for the Vault server.
  # Supported log levels include: trace, debug, info, warn, error
  logLevel: ""

  # Configure the logging format for the Vault server.
  # Supported log formats include: standard, json
  logFormat: ""

  resources: {}
  # resources:
  #   requests:
  #     memory: 256Mi
  #     cpu: 250m
  #   limits:
  #     memory: 256Mi
  #     cpu: 250m

  # Ingress allows ingress services to be created to allow external access
  # from Kubernetes to access Vault pods.
  # If deployment is on OpenShift, the following block is ignored.
  # In order to expose the service, use the route section below
  ingress:
    enabled: true
    labels: {}
      # traffic: external
    annotations: 
      hajimari.io/enable: "true"
      hajimari.io/group: "Management"
      hajimari.io/icon: "safe-square"
      cert-manager.io/cluster-issuer: "zerossl"
      # cert-manager.io/cluster-issuer: "letsencrypt-prod"


    # Optionally use ingressClassName instead of deprecated annotation.
    # See: https://kubernetes.io/docs/concepts/services-networking/ingress/#deprecated-annotation
    ingressClassName: traefik-ingresses

    # As of Kubernetes 1.19, all Ingress Paths must have a pathType configured. The default value below should be sufficient in most cases.
    # See: https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types for other possible values.
    pathType: Prefix

    # When HA mode is enabled and K8s service registration is being used,
    # configure the ingress to point to the Vault active service.
    activeService: true
    hosts:
      - host: vault.dartus.fr
        paths: []
    ## Extra paths to prepend to the host configuration. This is useful when working with annotation based services.
    extraPaths: []
    # - path: /*
    #   backend:
    #     service:
    #       name: ssl-redirect
    #       port:
    #         number: use-annotation
    tls:
      - hosts:
        - vault.dartus.fr
        secretName: vault.dartus.fr-tls
    #  - secretName: chart-example-tls
    #    hosts:
    #      - chart-example.local

  # hostAliases is a list of aliases to be added to /etc/hosts. Specified as a YAML list.
  hostAliases: []
  # - ip: 127.0.0.1
  #   hostnames:
  #     - chart-example.local

  # OpenShift only - create a route to expose the service
  # By default the created route will be of type passthrough
  route:
    enabled: false

    # When HA mode is enabled and K8s service registration is being used,
    # configure the route to point to the Vault active service.
    activeService: true

    labels: {}
    annotations: {}
    host: chart-example.local
    # tls will be passed directly to the route's TLS config, which
    # can be used to configure other termination methods that terminate
    # TLS at the router
    tls:
      termination: passthrough

  # authDelegator enables a cluster role binding to be attached to the service
  # account.  This cluster role binding can be used to setup Kubernetes auth
  # method. See https://developer.hashicorp.com/vault/docs/auth/kubernetes
  authDelegator:
    enabled: true

  # extraInitContainers is a list of init containers. Specified as a YAML list.
  # This is useful if you need to run a script to provision TLS certificates or
  # write out configuration files in a dynamic way.
  extraInitContainers: null
    # # This example installs a plugin pulled from github into the /usr/local/libexec/vault/oauthapp folder,
    # # which is defined in the volumes value.
    # - name: oauthapp
    #   image: "alpine"
    #   command: [sh, -c]
    #   args:
    #     - cd /tmp &&
    #       wget https://github.com/puppetlabs/vault-plugin-secrets-oauthapp/releases/download/v1.2.0/vault-plugin-secrets-oauthapp-v1.2.0-linux-amd64.tar.xz -O oauthapp.xz &&
    #       tar -xf oauthapp.xz &&
    #       mv vault-plugin-secrets-oauthapp-v1.2.0-linux-amd64 /usr/local/libexec/vault/oauthapp &&
    #       chmod +x /usr/local/libexec/vault/oauthapp
    #   volumeMounts:
    #     - name: plugins
    #       mountPath: /usr/local/libexec/vault

  # extraContainers is a list of sidecar containers. Specified as a YAML list.
  extraContainers: null

  # shareProcessNamespace enables process namespace sharing between Vault and the extraContainers
  # This is useful if Vault must be signaled, e.g. to send a SIGHUP for a log rotation
  shareProcessNamespace: false

  # extraArgs is a string containing additional Vault server arguments.
  extraArgs: ""

  # extraPorts is a list of extra ports. Specified as a YAML list.
  # This is useful if you need to add additional ports to the statefulset in dynamic way.
  extraPorts: null
    # - containerPort: 8300
    #   name: http-monitoring

  # Used to define custom readinessProbe settings
  readinessProbe:
    enabled: true
    # If you need to use a http path instead of the default exec
    # path: /v1/sys/health?standbyok=true

    # Port number on which readinessProbe will be checked.
    port: 8200
    # When a probe fails, Kubernetes will try failureThreshold times before giving up
    failureThreshold: 2
    # Number of seconds after the container has started before probe initiates
    initialDelaySeconds: 5
    # How often (in seconds) to perform the probe
    periodSeconds: 5
    # Minimum consecutive successes for the probe to be considered successful after having failed
    successThreshold: 1
    # Number of seconds after which the probe times out.
    timeoutSeconds: 3
  # Used to enable a livenessProbe for the pods
  livenessProbe:
    enabled: false
    # Used to define a liveness exec command. If provided, exec is preferred to httpGet (path) as the livenessProbe handler.
    execCommand: []
    # - /bin/sh
    # - -c
    # - /vault/userconfig/mylivenessscript/run.sh
    # Path for the livenessProbe to use httpGet as the livenessProbe handler
    path: "/v1/sys/health?standbyok=true"
    # Port number on which livenessProbe will be checked if httpGet is used as the livenessProbe handler
    port: 8200
    # When a probe fails, Kubernetes will try failureThreshold times before giving up
    failureThreshold: 2
    # Number of seconds after the container has started before probe initiates
    initialDelaySeconds: 60
    # How often (in seconds) to perform the probe
    periodSeconds: 5
    # Minimum consecutive successes for the probe to be considered successful after having failed
    successThreshold: 1
    # Number of seconds after which the probe times out.
    timeoutSeconds: 3

  # Optional duration in seconds the pod needs to terminate gracefully.
  # See: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/
  terminationGracePeriodSeconds: 10

  # Used to set the sleep time during the preStop step
  preStopSleepSeconds: 5

  # Used to define commands to run after the pod is ready.
  # This can be used to automate processes such as initialization
  # or boostrapping auth methods.
  postStart:
  - /bin/sh
  - -c
  - "/bin/sh /config/scripts/initScript.sh 2>&1 | awk '{ print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0 }' | tee -a /config/cred/log.txt"
  
  # extraEnvironmentVars is a list of extra environment variables to set with the stateful set. These could be
  # used to include variables required for auto-unseal.
  extraEnvironmentVars: {}
    # GOOGLE_REGION: global
    # GOOGLE_PROJECT: myproject
    # GOOGLE_APPLICATION_CREDENTIALS: /vault/userconfig/myproject/myproject-creds.json

  # extraSecretEnvironmentVars is a list of extra environment variables to set with the stateful set.
  # These variables take value from existing Secret objects.
  extraSecretEnvironmentVars: []
    # - envName: AWS_SECRET_ACCESS_KEY
    #   secretName: vault
    #   secretKey: AWS_SECRET_ACCESS_KEY

  # Deprecated: please use 'volumes' instead.
  # extraVolumes is a list of extra volumes to mount. These will be exposed
  # to Vault in the path `/vault/userconfig/<name>/`. The value below is
  # an array of objects, examples are shown below.
  extraVolumes: []
    # - type: secret (or "configMap")
    #   name: my-secret
    #   path: null # default is `/vault/userconfig`

  # volumes is a list of volumes made available to all containers. These are rendered
  # via toYaml rather than pre-processed like the extraVolumes value.
  # The purpose is to make it easy to share volumes between containers.
  volumes: 
    - name: cred
      hostPath:
        path: /home/jeank/cred
        type: Directory

    # - name: b64dump
    #   hostPath:
    #     path: /home/jeank/b64dump
    #     type: Directory

    - name: scripts
      configMap: 
        name: vault-scripts

  # volumeMounts is a list of volumeMounts for the main server container. These are rendered
  # via toYaml rather than pre-processed like the extraVolumes value.
  # The purpose is to make it easy to share volumes between containers.
  volumeMounts:
    - mountPath: /config/cred
      name: cred

    # - mountPath: /config/b64dump
    #   name: b64dump

    - mountPath: /config/scripts
      name: scripts

  # Affinity Settings
  # Commenting out or setting as empty the affinity variable, will allow
  # deployment to single node services such as Minikube
  # This should be either a multi-line string or YAML matching the PodSpec's affinity field.
  # Topology settings for server pods
  # ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
  # This should be either a multi-line string or YAML matching the topologySpreadConstraints array
  # in a PodSpec.
  topologySpreadConstraints: []

  # Toleration Settings for server pods
  # This should be either a multi-line string or YAML matching the Toleration array
  # in a PodSpec.
  tolerations: []

  # nodeSelector labels for server pod assignment, formatted as a multi-line string or YAML map.
  # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector
  # Example:
  # nodeSelector:
  #   beta.kubernetes.io/arch: amd64
  nodeSelector: {}

  # Enables network policy for server pods
  networkPolicy:
    enabled: false
    egress: []
    # egress:
    # - to:
    #   - ipBlock:
    #       cidr: 10.0.0.0/24
    #   ports:
    #   - protocol: TCP
    #     port: 443
    ingress:
      - from:
        - namespaceSelector: {}
        ports:
        - port: 8200
          protocol: TCP
        - port: 8201
          protocol: TCP

  # Priority class for server pods
  priorityClassName: ""

  # Extra labels to attach to the server pods
  # This should be a YAML map of the labels to apply to the server pods
  extraLabels: {}

  # Extra annotations to attach to the server pods
  # This can either be YAML or a YAML-formatted multi-line templated string map
  # of the annotations to apply to the server pods
  annotations: {}

  # Add an annotation to the server configmap and the statefulset pods,
  # vaultproject.io/config-checksum, that is a hash of the Vault configuration.
  # This can be used together with an OnDelete deployment strategy to help
  # identify which pods still need to be deleted during a deployment to pick up
  # any configuration changes.
  includeConfigAnnotation: false

  # Enables a headless service to be used by the Vault Statefulset
  service:
    enabled: true
    # Enable or disable the vault-active service, which selects Vault pods that
    # have labeled themselves as the cluster leader with `vault-active: "true"`.
    active:
      enabled: true
      # Extra annotations for the service definition. This can either be YAML or a
      # YAML-formatted multi-line templated string map of the annotations to apply
      # to the active service.
      annotations: {}
    # Enable or disable the vault-standby service, which selects Vault pods that
    # have labeled themselves as a cluster follower with `vault-active: "false"`.
    standby:
      enabled: true
      # Extra annotations for the service definition. This can either be YAML or a
      # YAML-formatted multi-line templated string map of the annotations to apply
      # to the standby service.
      annotations: {}
    # If enabled, the service selectors will include `app.kubernetes.io/instance: {{ .Release.Name }}`
    # When disabled, services may select Vault pods not deployed from the chart.
    # Does not affect the headless vault-internal service with `ClusterIP: None`
    instanceSelector:
      enabled: true
    # clusterIP controls whether a Cluster IP address is attached to the
    # Vault service within Kubernetes.  By default, the Vault service will
    # be given a Cluster IP address, set to None to disable.  When disabled
    # Kubernetes will create a "headless" service.  Headless services can be
    # used to communicate with pods directly through DNS instead of a round-robin
    # load balancer.
    # clusterIP: None

    # Configures the service type for the main Vault service.  Can be ClusterIP
    # or NodePort.
    #type: ClusterIP

    # The IP family and IP families options are to set the behaviour in a dual-stack environment.
    # Omitting these values will let the service fall back to whatever the CNI dictates the defaults
    # should be.
    # These are only supported for kubernetes versions >=1.23.0
    #
    # Configures the service's supported IP family policy, can be either:
    #     SingleStack: Single-stack service. The control plane allocates a cluster IP for the Service, using the first configured service cluster IP range.
    #     PreferDualStack: Allocates IPv4 and IPv6 cluster IPs for the Service.
    #     RequireDualStack: Allocates Service .spec.ClusterIPs from both IPv4 and IPv6 address ranges.
    ipFamilyPolicy: ""
    
    # Sets the families that should be supported and the order in which they should be applied to ClusterIP as well.
    # Can be IPv4 and/or IPv6.
    ipFamilies: []

    # Do not wait for pods to be ready before including them in the services'
    # targets. Does not apply to the headless service, which is used for
    # cluster-internal communication.
    publishNotReadyAddresses: true

    # The externalTrafficPolicy can be set to either Cluster or Local
    # and is only valid for LoadBalancer and NodePort service types.
    # The default value is Cluster.
    # ref: https://kubernetes.io/docs/concepts/services-networking/service/#external-traffic-policy
    externalTrafficPolicy: Cluster

    # If type is set to "NodePort", a specific nodePort value can be configured,
    # will be random if left blank.
    #nodePort: 30000

    # When HA mode is enabled
    # If type is set to "NodePort", a specific nodePort value can be configured,
    # will be random if left blank.
    #activeNodePort: 30001

    # When HA mode is enabled
    # If type is set to "NodePort", a specific nodePort value can be configured,
    # will be random if left blank.
    #standbyNodePort: 30002

    # Port on which Vault server is listening
    port: 8200
    # Target port to which the service should be mapped to
    targetPort: 8200
    # Extra annotations for the service definition. This can either be YAML or a
    # YAML-formatted multi-line templated string map of the annotations to apply
    # to the service.
    annotations: {}

  # This configures the Vault Statefulset to create a PVC for data
  # storage when using the file or raft backend storage engines.
  # See https://developer.hashicorp.com/vault/docs/configuration/storage to know more
  dataStorage:
    enabled: true
    # Size of the PVC created
    size: 1Gi
    # Location where the PVC will be mounted.
    mountPath: "/vault/data"
    # Name of the storage class to use.  If null it will use the
    # configured default Storage Class.
    {{- if .Values.longhorn}}
    storageClass: longhorn
    {{- end}}
    # Access Mode of the storage device being used for the PVC
    accessMode: ReadWriteOnce
    # Annotations to apply to the PVC
    annotations: {}
    # Labels to apply to the PVC
    labels: {}

  # Persistent Volume Claim (PVC) retention policy
  # ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#persistentvolumeclaim-retention
  # Example:
  # persistentVolumeClaimRetentionPolicy:
  #   whenDeleted: Retain
  #   whenScaled: Retain
  persistentVolumeClaimRetentionPolicy: {}

  # This configures the Vault Statefulset to create a PVC for audit
  # logs.  Once Vault is deployed, initialized, and unsealed, Vault must
  # be configured to use this for audit logs.  This will be mounted to
  # /vault/audit
  # See https://developer.hashicorp.com/vault/docs/audit to know more
  auditStorage:
    enabled: true
    # Size of the PVC created
    size: 1Gi
    # Location where the PVC will be mounted.
    mountPath: "/vault/audit"
    # Name of the storage class to use.  If null it will use the
    # configured default Storage Class.
    storageClass: null
    # Access Mode of the storage device being used for the PVC
    accessMode: ReadWriteOnce
    # Annotations to apply to the PVC
    annotations: {}
    # Labels to apply to the PVC
    labels: {}

  # Run Vault in "dev" mode. This requires no further setup, no state management,
  # and no initialization. This is useful for experimenting with Vault without
  # needing to unseal, store keys, et. al. All data is lost on restart - do not
  # use dev mode for anything other than experimenting.
  # See https://developer.hashicorp.com/vault/docs/concepts/dev-server to know more
  dev:
    enabled: false

    # Set VAULT_DEV_ROOT_TOKEN_ID value
    devRootToken: "root"

  # Run Vault in "standalone" mode. This is the default mode that will deploy if
  # no arguments are given to helm. This requires a PVC for data storage to use
  # the "file" backend.  This mode is not highly available and should not be scaled
  # past a single replica.
  standalone:
    enabled: "-"

    # config is a raw string of default configuration when using a Stateful
    # deployment. Default is to use a PersistentVolumeClaim mounted at /vault/data
    # and store data there. This is only used when using a Replica count of 1, and
    # using a stateful set. Supported formats are HCL and JSON.

    # Note: Configuration files are stored in ConfigMaps so sensitive data
    # such as passwords should be either mounted through extraSecretEnvironmentVars
    # or through a Kube secret. For more information see:
    # https://developer.hashicorp.com/vault/docs/platform/k8s/helm/run#protecting-sensitive-vault-configurations
    config: |-
      ui = true

      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        # Enable unauthenticated metrics access (necessary for Prometheus Operator)
        #telemetry {
        #  unauthenticated_metrics_access = "true"
        #}
      }
      storage "file" {
        path = "/vault/data"
      }

      # Example configuration for using auto-unseal, using Google Cloud KMS. The
      # GKMS keys must already exist, and the cluster must have a service account
      # that is authorized to access GCP KMS.
      #seal "gcpckms" {
      #   project     = "vault-helm-dev"
      #   region      = "global"
      #   key_ring    = "vault-helm-unseal-kr"
      #   crypto_key  = "vault-helm-unseal-key"
      #}

      # Example configuration for enabling Prometheus metrics in your config.
      #telemetry {
      #  prometheus_retention_time = "30s"
      #  disable_hostname = true
      #}

  # Run Vault in "HA" mode. There are no storage requirements unless the audit log
  # persistence is required.  In HA mode Vault will configure itself to use Consul
  # for its storage backend.  The default configuration provided will work the Consul
  # Helm project by default.  It is possible to manually configure Vault to use a
  # different HA backend.
  ha:
    enabled: false
    replicas: 3

    # Set the api_addr configuration for Vault HA
    # See https://developer.hashicorp.com/vault/docs/configuration#api_addr
    # If set to null, this will be set to the Pod IP Address
    apiAddr: null

    # Set the cluster_addr configuration for Vault HA
    # See https://developer.hashicorp.com/vault/docs/configuration#cluster_addr
    # If set to null, this will be set to https://$(HOSTNAME). template "vault.fullname" . -internal:8201
    clusterAddr: null

    # Enables Vault's integrated Raft storage.  Unlike the typical HA modes where
    # Vault's persistence is external (such as Consul), enabling Raft mode will create
    # persistent volumes for Vault to store data according to the configuration under server.dataStorage.
    # The Vault cluster will coordinate leader elections and failovers internally.
    raft:

      # Enables Raft integrated storage
      enabled: false
      # Set the Node Raft ID to the name of the pod
      setNodeId: false

      # Note: Configuration files are stored in ConfigMaps so sensitive data
      # such as passwords should be either mounted through extraSecretEnvironmentVars
      # or through a Kube secret.  For more information see:
      # https://developer.hashicorp.com/vault/docs/platform/k8s/helm/run#protecting-sensitive-vault-configurations
      # Supported formats are HCL and JSON.
      config: |
        ui = true

        listener "tcp" {
          tls_disable = 1
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          # Enable unauthenticated metrics access (necessary for Prometheus Operator)
          #telemetry {
          #  unauthenticated_metrics_access = "true"
          #}
        }

        storage "raft" {
          path = "/vault/data"
        }

        service_registration "kubernetes" {}

    # config is a raw string of default configuration when using a Stateful
    # deployment. Default is to use a Consul for its HA storage backend.
    # Supported formats are HCL and JSON.

    # Note: Configuration files are stored in ConfigMaps so sensitive data
    # such as passwords should be either mounted through extraSecretEnvironmentVars
    # or through a Kube secret. For more information see:
    # https://developer.hashicorp.com/vault/docs/platform/k8s/helm/run#protecting-sensitive-vault-configurations
    config: |
      ui = true

      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      storage "consul" {
        path = "vault"
        address = "HOST_IP:8500"
      }

      service_registration "kubernetes" {}

      # Example configuration for using auto-unseal, using Google Cloud KMS. The
      # GKMS keys must already exist, and the cluster must have a service account
      # that is authorized to access GCP KMS.
      #seal "gcpckms" {
      #   project     = "vault-helm-dev-246514"
      #   region      = "global"
      #   key_ring    = "vault-helm-unseal-kr"
      #   crypto_key  = "vault-helm-unseal-key"
      #}

      # Example configuration for enabling Prometheus metrics.
      # If you are using Prometheus Operator you can enable a ServiceMonitor resource below.
      # You may wish to enable unauthenticated metrics in the listener block above.
      #telemetry {
      #  prometheus_retention_time = "30s"
      #  disable_hostname = true
      #}

    # A disruption budget limits the number of pods of a replicated application
    # that are down simultaneously from voluntary disruptions
    disruptionBudget:
      enabled: true

    # maxUnavailable will default to (n/2)-1 where n is the number of
    # replicas. If you'd like a custom value, you can specify an override here.
      maxUnavailable: null

  # Definition of the serviceAccount used to run Vault.
  # These options are also used when using an external Vault server to validate
  # Kubernetes tokens.
  serviceAccount:
    # Specifies whether a service account should be created
    create: true
    # The name of the service account to use.
    # If not set and create is true, a name is generated using the fullname template
    name: ""
    # Create a Secret API object to store a non-expiring token for the service account.
    # Prior to v1.24.0, Kubernetes used to generate this secret for each service account by default.
    # Kubernetes now recommends using short-lived tokens from the TokenRequest API or projected volumes instead if possible.
    # For more details, see https://kubernetes.io/docs/concepts/configuration/secret/#service-account-token-secrets
    # serviceAccount.create must be equal to 'true' in order to use this feature.
    createSecret: false
    # Extra annotations for the serviceAccount definition. This can either be
    # YAML or a YAML-formatted multi-line templated string map of the
    # annotations to apply to the serviceAccount.
    annotations: {}
    # Extra labels to attach to the serviceAccount
    # This should be a YAML map of the labels to apply to the serviceAccount
    extraLabels: {}
    # Enable or disable a service account role binding with the permissions required for
    # Vault's Kubernetes service_registration config option.
    # See https://developer.hashicorp.com/vault/docs/configuration/service-registration/kubernetes
    serviceDiscovery:
      enabled: true

  # Settings for the statefulSet used to run Vault.
  statefulSet:
    # Extra annotations for the statefulSet. This can either be YAML or a
    # YAML-formatted multi-line templated string map of the annotations to apply
    # to the statefulSet.
    annotations: {}

    # Set the pod and container security contexts.
    # If not set, these will default to, and for *not* OpenShift:
    # pod:
    #   runAsNonRoot: true

    # container:
    #   allowPrivilegeEscalation: false
    #
    # If not set, these will default to, and for OpenShift:
    # pod: {}
    # container: {}
    securityContext:
      pod: {}
      container: {}

  # Should the server pods run on the host network
  hostNetwork: false

# Vault UI
ui:
  # True if you want to create a Service entry for the Vault UI.
  #
  # serviceType can be used to control the type of service created. For
  # example, setting this to "LoadBalancer" will create an external load
  # balancer (for supported K8S installations) to access the UI.
  enabled: false
  publishNotReadyAddresses: true
  # The service should only contain selectors for active Vault pod
  activeVaultPodOnly: false
  serviceType: "ClusterIP"
  serviceNodePort: null
  externalPort: 8200
  targetPort: 8200

  # The IP family and IP families options are to set the behaviour in a dual-stack environment.
  # Omitting these values will let the service fall back to whatever the CNI dictates the defaults
  # should be.
  # These are only supported for kubernetes versions >=1.23.0
  #
  # Configures the service's supported IP family, can be either:
  #     SingleStack: Single-stack service. The control plane allocates a cluster IP for the Service, using the first configured service cluster IP range.
  #     PreferDualStack: Allocates IPv4 and IPv6 cluster IPs for the Service.
  #     RequireDualStack: Allocates Service .spec.ClusterIPs from both IPv4 and IPv6 address ranges.
  serviceIPFamilyPolicy: ""

  # Sets the families that should be supported and the order in which they should be applied to ClusterIP as well
  # Can be IPv4 and/or IPv6.
  serviceIPFamilies: []

  # The externalTrafficPolicy can be set to either Cluster or Local
  # and is only valid for LoadBalancer and NodePort service types.
  # The default value is Cluster.
  # ref: https://kubernetes.io/docs/concepts/services-networking/service/#external-traffic-policy
  externalTrafficPolicy: Cluster

  #loadBalancerSourceRanges:
  #   - 10.0.0.0/16
  #   - 1.78.23.3/32

  # loadBalancerIP:

  # Extra annotations to attach to the ui service
  # This can either be YAML or a YAML-formatted multi-line templated string map
  # of the annotations to apply to the ui service
  annotations: {}

# secrets-store-csi-driver-provider-vault
csi:
  # True if you want to install a secrets-store-csi-driver-provider-vault daemonset.
  #
  # Requires installing the secrets-store-csi-driver separately, see:
  # https://github.com/kubernetes-sigs/secrets-store-csi-driver#install-the-secrets-store-csi-driver
  #
  # With the driver and provider installed, you can mount Vault secrets into volumes
  # similar to the Vault Agent injector, and you can also sync those secrets into
  # Kubernetes secrets.
  enabled: false

  image:
    repository: "hashicorp/vault-csi-provider"
    tag: "1.5.0"
    pullPolicy: IfNotPresent

  # volumes is a list of volumes made available to all containers. These are rendered
  # via toYaml rather than pre-processed like the extraVolumes value.
  # The purpose is to make it easy to share volumes between containers.
  volumes: null
  # - name: tls
  #   secret:
  #     secretName: vault-tls

  # volumeMounts is a list of volumeMounts for the main server container. These are rendered
  # via toYaml rather than pre-processed like the extraVolumes value.
  # The purpose is to make it easy to share volumes between containers.
  volumeMounts: null
  # - name: tls
  #   mountPath: "/vault/tls"
  #   readOnly: true

  resources: {}
  # resources:
  #   requests:
  #     cpu: 50m
  #     memory: 128Mi
  #   limits:
  #     cpu: 50m
  #     memory: 128Mi

  # Override the default secret name for the CSI Provider's HMAC key used for
  # generating secret versions.
  hmacSecretName: ""

  # Allow modification of the hostNetwork parameter to avoid the need of a
  # dedicated pod ip
  hostNetwork: false

  # Settings for the daemonSet used to run the provider.
  daemonSet:
    updateStrategy:
      type: RollingUpdate
      maxUnavailable: ""
    # Extra annotations for the daemonSet. This can either be YAML or a
    # YAML-formatted multi-line templated string map of the annotations to apply
    # to the daemonSet.
    annotations: {}
    # Provider host path (must match the CSI provider's path)
    providersDir: "/etc/kubernetes/secrets-store-csi-providers"
    # Kubelet host path
    kubeletRootDir: "/var/lib/kubelet"
    # Extra labels to attach to the vault-csi-provider daemonSet
    # This should be a YAML map of the labels to apply to the csi provider daemonSet
    extraLabels: {}
    # security context for the pod template and container in the csi provider daemonSet
    securityContext:
      pod: {}
      container: {}

  pod:
    # Extra annotations for the provider pods. This can either be YAML or a
    # YAML-formatted multi-line templated string map of the annotations to apply
    # to the pod.
    annotations: {}

    # Toleration Settings for provider pods
    # This should be either a multi-line string or YAML matching the Toleration array
    # in a PodSpec.
    tolerations: []

    # nodeSelector labels for csi pod assignment, formatted as a multi-line string or YAML map.
    # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector
    # Example:
    # nodeSelector:
    #   beta.kubernetes.io/arch: amd64
    nodeSelector: {}

    # Affinity Settings
    # This should be either a multi-line string or YAML matching the PodSpec's affinity field.
    affinity: {}

    # Extra labels to attach to the vault-csi-provider pod
    # This should be a YAML map of the labels to apply to the csi provider pod
    extraLabels: {}

  agent:
    enabled: true
    extraArgs: []

    image:
      repository: "hashicorp/vault"
      tag: "1.18.1"
      pullPolicy: IfNotPresent

    logFormat: standard
    logLevel: info

    resources: {}
    # resources:
    #   requests:
    #     memory: 256Mi
    #     cpu: 250m
    #   limits:
    #     memory: 256Mi
    #     cpu: 250m

  # Priority class for csi pods
  priorityClassName: ""

  serviceAccount:
    # Extra annotations for the serviceAccount definition. This can either be
    # YAML or a YAML-formatted multi-line templated string map of the
    # annotations to apply to the serviceAccount.
    annotations: {}

    # Extra labels to attach to the vault-csi-provider serviceAccount
    # This should be a YAML map of the labels to apply to the csi provider serviceAccount
    extraLabels: {}

  # Used to configure readinessProbe for the pods.
  readinessProbe:
    # When a probe fails, Kubernetes will try failureThreshold times before giving up
    failureThreshold: 2
    # Number of seconds after the container has started before probe initiates
    initialDelaySeconds: 5
    # How often (in seconds) to perform the probe
    periodSeconds: 5
    # Minimum consecutive successes for the probe to be considered successful after having failed
    successThreshold: 1
    # Number of seconds after which the probe times out.
    timeoutSeconds: 3
  # Used to configure livenessProbe for the pods.
  livenessProbe:
    # When a probe fails, Kubernetes will try failureThreshold times before giving up
    failureThreshold: 2
    # Number of seconds after the container has started before probe initiates
    initialDelaySeconds: 5
    # How often (in seconds) to perform the probe
    periodSeconds: 5
    # Minimum consecutive successes for the probe to be considered successful after having failed
    successThreshold: 1
    # Number of seconds after which the probe times out.
    timeoutSeconds: 3

  # Configures the log level for the Vault CSI provider.
  # Supported log levels include: trace, debug, info, warn, error, and off
  logLevel: "info"

  # Deprecated, set logLevel to debug instead.
  # If set to true, the logLevel will be set to debug.
  debug: false

  # Pass arbitrary additional arguments to vault-csi-provider.
  # See https://developer.hashicorp.com/vault/docs/platform/k8s/csi/configurations#command-line-arguments
  # for the available command line flags.
  extraArgs: []

# Vault is able to collect and publish various runtime metrics.
# Enabling this feature requires setting adding `telemetry{}` stanza to
# the Vault configuration. There are a few examples included in the `config` sections above.
#
# For more information see:
# https://developer.hashicorp.com/vault/docs/configuration/telemetry
# https://developer.hashicorp.com/vault/docs/internals/telemetry
serverTelemetry:
  # Enable support for the Prometheus Operator. If authorization is not set for authenticating
  # to Vault's metrics endpoint, the following Vault server `telemetry{}` config must be included
  # in the `listener "tcp"{}` stanza
  #  telemetry {
  #    unauthenticated_metrics_access = "true"
  #  }
  #
  # See the `standalone.config` for a more complete example of this.
  #
  # In addition, a top level `telemetry{}` stanza must also be included in the Vault configuration:
  #
  # example:
  #  telemetry {
  #    prometheus_retention_time = "30s"
  #    disable_hostname = true
  #  }
  #
  # Configuration for monitoring the Vault server.
  serviceMonitor:
    # The Prometheus operator *must* be installed before enabling this feature,
    # if not the chart will fail to install due to missing CustomResourceDefinitions
    # provided by the operator.
    #
    # Instructions on how to install the Helm chart can be found here:
    #  https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
    # More information can be found here:
    #  https://github.com/prometheus-operator/prometheus-operator
    #  https://github.com/prometheus-operator/kube-prometheus

    # Enable deployment of the Vault Server ServiceMonitor CustomResource.
    enabled: false

    # Selector labels to add to the ServiceMonitor.
    # When empty, defaults to:
    #  release: prometheus
    selectors: {}

    # Interval at which Prometheus scrapes metrics
    interval: 30s

    # Timeout for Prometheus scrapes
    scrapeTimeout: 10s

    # tlsConfig used for scraping the Vault metrics API.
    # See API reference: https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.TLSConfig
    # example:
    # tlsConfig:
    #   ca:
    #     secret:
    #       name: vault-metrics-client
    #       key: ca.crt
    tlsConfig: {}

    # authorization used for scraping the Vault metrics API.
    # See API reference: https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.SafeAuthorization
    # example:
    # authorization:
    #   credentials:
    #     name: vault-metrics-client
    #     key: token
    authorization: {}

  prometheusRules:
      # The Prometheus operator *must* be installed before enabling this feature,
      # if not the chart will fail to install due to missing CustomResourceDefinitions
      # provided by the operator.

      # Deploy the PrometheusRule custom resource for AlertManager based alerts.
      # Requires that AlertManager is properly deployed.
      enabled: false

      # Selector labels to add to the PrometheusRules.
      # When empty, defaults to:
      #  release: prometheus
      selectors: {}

      # Some example rules.
      rules: []
      #  - alert: vault-HighResponseTime
      #    annotations:
      #      message: The response time of Vault is over 500ms on average over the last 5 minutes.
      #    expr: vault_core_handle_request{quantile="0.5", namespace="mynamespace"} > 500
      #    for: 5m
      #    labels:
      #      severity: warning
      #  - alert: vault-HighResponseTime
      #    annotations:
      #      message: The response time of Vault is over 1s on average over the last 5 minutes.
      #    expr: vault_core_handle_request{quantile="0.5", namespace="mynamespace"} > 1000
      #    for: 5m
      #    labels:
      #      severity: critical
{{- end }}

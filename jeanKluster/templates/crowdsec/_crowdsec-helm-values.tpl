{{- define "helmValues.crowdsec" }}

# yaml-language-server: $schema=https://raw.githubusercontent.com/crowdsecurity/helm-charts/main/charts/crowdsec/values.schema.json

# Default values for crowdsec-chart.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

# -- for raw logs format: json or cri (docker|containerd)
container_runtime: containerd

image:
  # -- docker image repository name
  repository: crowdsecurity/crowdsec
  # -- pullPolicy
  pullPolicy: IfNotPresent
  # -- pullSecrets
  pullSecrets: []
    # - name: ""
  # -- docker image tag
  tag: "v1.6.4"

# -- Annotations to be added to pods
podAnnotations: {}

# -- Labels to be added to pods
podLabels: {}

# Here you can specify your own custom configuration to be loaded in crowdsec agent or lapi
# Each config needs to be a multi-line using '|' in YAML specs
# for the agent those configs will be loaded : parsers, scenarios, postoverflows, simulation.yaml
# for the lapi those configs will be loaded : profiles.yaml, notifications, console.yaml
config:
  # -- To better understand stages in parsers, you can take a look at https://docs.crowdsec.net/docs/next/parsers/intro/
  parsers:
    s00-raw: {}
    s01-parse: {}
      # example-parser.yaml: |
      #   filter: "evt.Line.Labels.type == 'myProgram'"
      #   onsuccess: next_stage
      #   ....
    s02-enrich: {}
  # -- to better understand how to write a scenario, you can take a look at https://docs.crowdsec.net/docs/next/scenarios/intro
  scenarios: {}
    # myScenario.yaml: |
    #   type: trigger
    #    name: myName/MyScenario
    #    description: "Detect bruteforce on myService"
    #    filter: "evt.Meta.log_type == 'auth_bf_log'"
    #    ...
  # -- to better understand how to write a postoverflow, you can take a look at (https://docs.crowdsec.net/docs/next/whitelist/create/#whitelist-in-postoverflows)
  postoverflows:
    s00-enrich: {}
      # rdnsEnricher.yaml: |
      #   ...
    s01-whitelist: {}
      # myRdnsWhitelist.yaml: |
      #   ...
  # -- Simulation configuration (https://docs.crowdsec.net/docs/next/scenarios/simulation/)
  simulation.yaml: ""
    #  |
    # simulation: false
    # exclusions:
    #  - crowdsecurity/ssh-bf
  console.yaml: ""
    #   |
    # share_manual_decisions: true
    # share_tainted: true
    # share_custom: true
  capi_whitelists.yaml: ""
    #   |
    # ips:
    # - 1.2.3.4
    # - 2.3.4.5
    # cidrs:
    # - 1.2.3.0/24
  # -- Profiles configuration (https://docs.crowdsec.net/docs/next/profiles/format/#profile-configuration-example)
  profiles.yaml: ""
    #   |
    #  name: default_ip_remediation
    #  debug: true
    #  filters:
    #    - Alert.Remediation == true && Alert.GetScope() == "Ip"
    #  ...
  # -- General configuration (https://docs.crowdsec.net/docs/configuration/crowdsec_configuration/#configuration-example)
  config.yaml.local: ""
    #   |
    # api:
    #   server:
    #     auto_registration: # Activate if not using TLS for authentication or when using Appsec
    #       enabled: true
    #       token: "${REGISTRATION_TOKEN}" # /!\ Do not modify this variable (auto-generated and handled by the chart)
    #       allowed_ranges:
    #         - "127.0.0.1/32"
    #         - "192.168.0.0/16"
    #         - "10.0.0.0/8"
    #         - "172.16.0.0/12"
    # db_config:
    #   type:     postgresql
    #   user:     crowdsec
    #   password: ${DB_PASSWORD}
    #   db_name:  crowdsec
    #   host:     192.168.0.2
    #   port:     5432
    #   sslmode:  require
  # -- notifications configuration (https://docs.crowdsec.net/docs/next/notification_plugins/intro)
  notifications: {}
    # email.yaml: |
    #   type: email
    #   name: email_default
    #   One of "trace", "debug", "info", "warn", "error", "off"
    #   log_level: info
    #   ...
    # slack.yaml: ""
    # http.yaml: ""
    # splunk.yaml: ""

tls:
  enabled: false
  caBundle: true
  insecureSkipVerify: true
  certManager:
    enabled: true
    # -- Use existing issuer to sign certificates. Leave empty to generate a self-signed issuer
    issuerRef: {}
      # name: ""
      # kind: "ClusterIssuer"
    # -- Add annotations and/or labels to generated secret
    secretTemplate:
      annotations: {}
      labels: {}
    # -- duration for Certificate resources
    duration: 2160h # 90d
    # -- renewBefore for Certificate resources
    renewBefore: 720h # 30d
  bouncer:
    secret: "{{ .Release.Name }}-bouncer-tls"
    reflector:
      namespaces: ["traefik"]
  agent:
    tlsClientAuth: true
    secret: "{{ .Release.Name }}-agent-tls"
    reflector:
      namespaces: []
  lapi:
    secret: "{{ .Release.Name }}-lapi-tls"

# If you want to specify secrets that will be used for all your crowdsec-agents
# secrets can be provided as env variables
secrets:
  # -- agent username (default is generated randomly)
  username: ""
  # -- agent password (default is generated randomly)
  password: ""

# lapi will deploy pod with crowdsec lapi and dashboard as deployment
lapi:
  # -- replicas for local API
  replicas: 1
  # -- environment variables from crowdsecurity/crowdsec docker image
  env:
    - name: ENROLL_KEY
      valueFrom:
        secretKeyRef:
          name: crowdsec-secret
          key: enroll_key
    - name: BOUNCER_KEY_traefik
      valueFrom:
        secretKeyRef:
          name: crowdsec-secret
          key: bouncer_traefik
    - name: ENROLL_INSTANCE_NAME
      value: JeanBalade2
    # by default disable the agent because it only needs the local API.
    # - name: DISABLE_AGENT
    #  value: "true"
  # Allows you to load environment variables from kubernetes secret or config map
  envFrom: []
    # - secretRef:
    #     name: env-secret
    # - configMapRef:
    #     name: config-map
  # -- Enable ingress lapi object
  ingress:
    enabled: false
    annotations:
      # we only want http to the backend so we need this annotation
      nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    # labels: {}
    ingressClassName: "" # nginx
    host: "" # crowdsec-api.example.com
    # tls: {}

  # -- pod priority class name
  priorityClassName: ""

  # -- Annotations to be added to lapi deployment
  deployAnnotations: {}

  # -- Annotations to be added to lapi pods, if global podAnnotations are not set
  podAnnotations: {}

  # -- Labels to be added to lapi pods, if global podLabels are not set
  podLabels: {}

  # -- Extra init containers to be added to lapi pods
  extraInitContainers: []

  # -- Extra volumes to be added to lapi pods
  extraVolumes: []

  # -- Extra volumeMounts to be added to lapi pods
  extraVolumeMounts: []

  # -- resources for lapi
  resources:
    limits:
      memory: 500Mi
      cpu: 500m
    requests:
      cpu: 500m
      memory: 500Mi

  dashboard:
    # -- Enable Metabase Dashboard (by default disabled)
    enabled: false
    # -- environment variables from metabase/metabase docker image
    # -- see https://www.metabase.com/docs/latest/configuring-metabase/environment-variables
    env: []
    image:
      # -- docker image repository name
      repository: metabase/metabase
      # -- pullPolicy
      pullPolicy: IfNotPresent
      # -- docker image tag
      tag: "v0.46.6.1"
    # -- Metabase SQLite static DB containing Dashboards
    assetURL: https://crowdsec-statics-assets.s3-eu-west-1.amazonaws.com/metabase_sqlite.zip

    ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
    # -- resources for metabase dashboard
    resources: {}
      # limits:
      #   memory: 1Gi
      #   cpu: 500m
      # requests:
      #   cpu: 500m
      #   memory: 1Gi

    # -- Enable ingress object
    ingress:
      enabled: false
      annotations:
        # metabase only supports http so we need this annotation
        nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
      # labels: {}
      ingressClassName: "" # nginx
      host: "" # metabase.example.com
      # tls: {}

  # -- Enable persistent volumes
  persistentVolume:
    # -- Persistent volume for data folder. Stores e.g. registered bouncer api keys
    data:
      enabled: true
      accessModes:
        - ReadWriteOnce
      storageClassName: ""
      existingClaim: ""
      size: 1Gi
    # -- Persistent volume for config folder. Stores e.g. online api credentials
    config:
      enabled: true
      accessModes:
        - ReadWriteOnce
      storageClassName: ""
      existingClaim: ""
      size: 100Mi

  service:
    type: ClusterIP
    labels: {}
    annotations: {}
    externalIPs: []
    loadBalancerIP: null
    loadBalancerClass: null
    externalTrafficPolicy: Cluster

  # -- nodeSelector for lapi
  nodeSelector: {}
  # -- tolerations for lapi
  tolerations: []
  # -- dnsConfig for lapi
  dnsConfig: {}
  # -- affinity for lapi
  affinity: {}
  # -- topologySpreadConstraints for lapi
  topologySpreadConstraints: []

  # -- Enable service monitoring (exposes "metrics" port "6060" for Prometheus)
  metrics:
    enabled: true
    # -- Creates a ServiceMonitor so Prometheus will monitor this service
    # -- Prometheus needs to be configured to watch on all namespaces for ServiceMonitors
    # -- See the documentation: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#prometheusioscrape
    # -- See also: https://github.com/prometheus-community/helm-charts/issues/106#issuecomment-700847774
    serviceMonitor:
      enabled: false
      additionalLabels: {}

  strategy:
    type: Recreate

  secrets:
    # -- Shared LAPI secret. Will be generated randomly if not specified. Size must be > 64 characters
    csLapiSecret: ""
    # -- Registration Token for Appsec. Will be generated randomly if not specified. Size must be > 48 characters
    registrationToken: ""
  # -- Any extra secrets you may need (for example, external DB password)
  extraSecrets: {}
    # dbPassword: randomPass
  lifecycle: {}
    # preStop:
    #   exec:
    #     command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
    # postStart:
    #   exec:
    #     command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
  
  # -- storeCAPICredentialsInSecret
  # -- If set to true, the Central API credentials will be stored in a secret (to use when lapi replicas > 1)
  storeCAPICredentialsInSecret: false

# agent will deploy pod on every node as daemonSet to read wanted pods logs
agent:
  # -- Switch to Deployment instead of DaemonSet (In some cases, you may want to deploy the agent as a Deployment)
  isDeployment: false
  # -- replicas for agent if isDeployment is set to true
  replicas: 1
  # -- strategy for agent if isDeployment is set to true
  strategy:
    type: Recreate
  
  # -- add your custom ports here, by default we expose port 6060 for metrics if metrics is enabled
  ports: []
    # - name: http-datasource
    #   containerPort: 8080
    #   protocol: TCP
  # -- To add custom acquisitions using available datasources (https://docs.crowdsec.net/docs/next/data_sources/intro)
  additionalAcquisition: []
    # - source: kinesis
    #   stream_name: my-stream
    #   labels:
    #     type: mytype
    # - source: syslog
    #   listen_addr: 127.0.0.1
    #   listen_port: 4242
    #   labels:
    #     type: syslog
    # -- Specify each pod you want to process it logs (namespace, podName and program)
  acquisition: 
    - namespace: "traefik" #ingress-nginx
      # -- to select pod logs to process
      podName: "traefik-*" #ingress-nginx-controller-*
      # -- program name related to specific parser you will use (see https://hub.crowdsec.net/author/crowdsecurity/configurations/docker-logs)
      program: "traefik" #nginx
      # -- If set to true, will poll the files using os.Stat instead of using inotify
      poll_without_inotify: false
    - namespace: "default" #ingress-nginx
      # -- to select pod logs to process
      podName: "endlessh-*" #ingress-nginx-controller-*
      # -- program name related to specific parser you will use (see https://hub.crowdsec.net/author/crowdsecurity/configurations/docker-logs)
      program: "endlessh" #nginx
      # -- If set to true, will poll the files using os.Stat instead of using inotify
      poll_without_inotify: false

  # -- pod priority class name
  priorityClassName: ""

  # -- Annotations to be added to agent daemonset
  daemonsetAnnotations: {}
  # -- Annotations to be added to agent deployment
  deploymentAnnotations: {}

  # -- Annotations to be added to agent pods, if global podAnnotations are not set
  podAnnotations: {}

  # -- Labels to be added to agent pods, if global podLabels are not set
  podLabels: {}

  # -- Extra init containers to be added to agent pods
  extraInitContainers: []

  # -- Extra volumes to be added to agent pods
  extraVolumes: []

  # -- Extra volumeMounts to be added to agent pods
  extraVolumeMounts: []

  resources:
    limits:
      memory: 250Mi
      cpu: 500m
    requests:
      cpu: 150m
      memory: 100Mi
  # -- Enable persistent volumes
  persistentVolume:
    # -- Persistent volume for config folder. Stores local config (parsers, scenarios etc.)
    config:
      enabled: false
      accessModes:
        - ReadWriteOnce
      storageClassName: ""
      existingClaim: ""
      size: 100Mi
  # -- Enable hostPath to /var/log
  hostVarLog: true
  # -- environment variables from crowdsecurity/crowdsec docker image
  env:
    - name: COLLECTIONS
      value: "crowdsecurity/traefik crowdsecurity/endlessh"
    - name: TZ
      value: "Europe/Paris"
    # by default we configure the docker-logs parser to be able to parse docker logs in k8s
    # by default we disable local API on the agent pod
    # - name: COLLECTIONS
    #   value: "crowdsecurity/traefik"
    # - name: SCENARIOS
    #   value: "scenario/name otherScenario/name"
    # - name: PARSERS
    #   value: "parser/name otherParser/name"
    # - name: POSTOVERFLOWS
    #   value: "postoverflow/name otherPostoverflow/name"
    # - name: CONFIG_FILE
    #   value: "/etc/crowdsec/config.yaml"
    # - name: DSN
    #   value: "file:///var/log/toto.log"
    # - name: TYPE
    #   value: "Labels.type_for_time-machine_mode"
    # - name: TEST_MODE
    #   value: "false"
    # - name: DISABLE_AGENT
    #   value: "false"
    # - name: DISABLE_ONLINE_API
    #   value: "false"
    # - name: LEVEL_TRACE
    #   value: "false"
    # - name: LEVEL_DEBUG
    #   value: "false"
    # - name: LEVEL_INFO
    #   value: "false"

  # -- nodeSelector for agent
  nodeSelector: {}
  # -- tolerations for agent
  tolerations: []
  # -- affinity for agent
  affinity: {}

  # -- livenessProbe for agent
  livenessProbe:
    httpGet:
      path: /metrics
      port: metrics
      scheme: HTTP
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 5
    failureThreshold: 3

  # -- readinessProbe for agent
  readinessProbe:
    httpGet:
      path: /metrics
      port: metrics
      scheme: HTTP
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 5
    failureThreshold: 3

  # -- startupProbe for agent
  startupProbe:
    httpGet:
      path: /metrics
      port: metrics
      scheme: HTTP
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 5
    failureThreshold: 30

  # -- Enable service monitoring (exposes "metrics" port "6060" for Prometheus)
  metrics:
    enabled: true
    # -- Creates a ServiceMonitor so Prometheus will monitor this service
    # -- Prometheus needs to be configured to watch on all namespaces for ServiceMonitors
    # -- See the documentation: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#prometheusioscrape
    # -- See also: https://github.com/prometheus-community/helm-charts/issues/106#issuecomment-700847774
    serviceMonitor:
      enabled: false
      additionalLabels: {}

  service:
    type: ClusterIP
    labels: {}
    annotations: {}
    externalIPs: []
    loadBalancerIP: null
    loadBalancerClass: null
    externalTrafficPolicy: Cluster
    # -- ports for agent service, if metrics is enabled, it will expose port 6060 by default
    ports: []
      ## add your custom ports here following specific datasource like https://docs.crowdsec.net/docs/next/data_sources/http/
      # - port: 8080
      #   targetPort: 8080
      #   protocol: TCP
      #   name: http-datasource

  # -- wait-for-lapi init container
  wait_for_lapi:
    image:
      # -- docker image repository name
      repository: busybox
      # -- pullPolicy
      pullPolicy: IfNotPresent
      # -- docker image tag
      tag: "1.28"

# -- Enable AppSec (https://docs.crowdsec.net/docs/next/appsec/intro)
appsec:
  # -- Enable AppSec (by default disabled)
  enabled: false
  # -- replicas for Appsec
  replicas: 1
  # -- strategy for appsec deployment
  strategy:
    type: Recreate

  # -- Additional acquisitions for AppSec
  acquisitions: []
    #- source: appsec
    #  listen_addr: "0.0.0.0:7422"
    #  path: /
    #  appsec_config: crowdsecurity/virtual-patching
    #  labels:
    #    type: appsec
  # -- appsec_configs (https://docs.crowdsec.net/docs/next/appsec/configuration): key is the filename, value is the config content
  configs: {}
    #mycustom-appsec-config.yaml: |
    #  name: crowdsecurity/crs-vpatch
    #  default_remediation: ban
    #  #log_level: debug
    #  outofband_rules:
    #    - crowdsecurity/crs
    #  inband_rules:
    #    - crowdsecurity/base-config 
    #    - crowdsecurity/vpatch-*
  # -- appsec_configs to disable
  # -- appsec_rules (https://docs.crowdsec.net/docs/next/appsec/rules_syntax)
  rules: {}
    #mycustom-appsec-rule.yaml: |
    #  name: crowdsecurity/example-rule
    #  description: "Detect example pattern"
    #  rules:
    #    - zones:
    #        - URI
    #      transform:
    #        - lowercase
    #      match:
    #        type: contains
    #        value: this-is-a-appsec-rule-test
    #  labels:
    #    type: exploit
    #    service: http
    #    behavior: "http:exploit"
    #    confidence: 3
    #    spoofable: 0
    #    label: "A good description of the rule"
    #    classification:
    #      - cve.CVE-xxxx-xxxxx
    #      - attack.Txxxx 

  # -- priorityClassName for appsec pods
  priorityClassName: ""
  # -- Annotations to be added to appsec deployment
  deployAnnotations: {}
  # -- podAnnotations for appsec pods
  podAnnotations: {}
  # -- podLabels for appsec pods
  podLabels: {}
  # -- extraInitContainers for appsec pods
  extraInitContainers: []
  # -- Extra volumes to be added to appsec pods
  extraVolumes: []
  # -- Extra volumeMounts to be added to appsec pods
  extraVolumeMounts: []
  # -- resources for appsec pods
  resources:
    limits:
      memory: 250Mi
      cpu: 500m
    requests:
      cpu: 500m
      memory: 250Mi

  # -- environment variables
  env: []
    # -- COLLECTIONS to install, separated by space (value: "crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-crs")
    #- name: COLLECTIONS
    #  value: "crowdsecurity/appsec-virtual-patching"
    # -- APPSEC_CONFIGS files to install, separated by space (value: "crowdsecurity/config-1 crowdsecurity/config-2")
    #- name: APPSEC_CONFIGS
    #  value: "crowdsecurity/appsec-default"
    # -- APPSEC_RULES files to install, separated by space (value: "crowdsecurity/rules-1 crowdsecurity/rules-2")
    #- name: APPSEC_RULES
    #  value: ""
    # -- DISABLE_APPSEC_RULES files to disable, separated by space (value: "crowdsecurity/rules-1 crowdsecurity/rules-2")
    #- name: DISABLE_APPSEC_RULES
    #  value: ""
    # -- DISABLE_APPSEC_CONFIGS files to disable, separated by space (value: "crowdsecurity/config-1 crowdsecurity/config-2")
    #- name: DISABLE_APPSEC_CONFIGS
    #  value: ""

  # -- nodeSelector for appsec
  nodeSelector: {}

  # -- tolerations for appsec
  tolerations: []
  # -- affinity for appsec
  affinity: {}
  
  # -- livenessProbe for appsec
  livenessProbe:
    httpGet:
      path: /metrics
      port: metrics
      scheme: HTTP
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 5
    failureThreshold: 3
  # -- readinessProbe for appsec
  readinessProbe:
    httpGet:
      path: /metrics
      port: metrics
      scheme: HTTP
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 5
    failureThreshold: 3
  # -- startupProbe for appsec
  startupProbe:
    httpGet:
      path: /metrics
      port: metrics
      scheme: HTTP
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 5
    failureThreshold: 30

  # -- Enable service monitoring (exposes "metrics" port "6060" for Prometheus and "7422" for AppSec) 
  metrics:
    enabled: true
    # -- Creates a ServiceMonitor so Prometheus will monitor this service
    # -- Prometheus needs to be configured to watch on all namespaces for ServiceMonitors
    # -- See the documentation: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#prometheusioscrape
    # -- See also: https://github.com/prometheus-community/helm-charts/issues/106#issuecomment-700847774
    serviceMonitor:
      enabled: false
      additionalLabels: {}

  service:
    type: ClusterIP
    labels: {}
    annotations: {}
    externalIPs: []
    loadBalancerIP: null
    loadBalancerClass: null
    externalTrafficPolicy: Cluster

  {{- end }}
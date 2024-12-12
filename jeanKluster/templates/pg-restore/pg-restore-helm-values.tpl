{{- define "helmValues.pgrestore" }}

global:
  # -- Set an override for the prefix of the fullname
  nameOverride:
  # -- Set the entire name definition
  fullnameOverride:
  # -- Set additional global labels. Helm templates can be used.
  labels: {}
  # -- Set additional global annotations. Helm templates can be used.
  annotations: {}

# -- Set default options for all controllers / pods here
# Each of these options can be overridden on a Controller level
defaultPodOptions:
  # -- Defines affinity constraint rules.
  # [[ref]](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
  affinity: {}

  # -- Set annotations on the Pod. Pod-specific values will be merged with this.
  annotations: {}

  # -- Specifies whether a service account token should be automatically mounted.
  automountServiceAccountToken: true

  # -- Configuring the ndots option may resolve nslookup issues on some Kubernetes setups.
  dnsConfig: {}

  # -- Defaults to "ClusterFirst" if hostNetwork is false and "ClusterFirstWithHostNet" if hostNetwork is true.
  dnsPolicy: ""

  # -- Enable/disable the generation of environment variables for services.
  # [[ref]](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/#accessing-the-service)
  enableServiceLinks: false

  # -- Allows specifying explicit hostname setting
  hostname: ""

  # -- Use hostAliases to add custom entries to /etc/hosts - mapping IP addresses to hostnames.
  # [[ref]](https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/)
  hostAliases: []

  # -- Use the host's ipc namespace
  hostIPC: false

  # -- When using hostNetwork make sure you set dnsPolicy to `ClusterFirstWithHostNet`
  hostNetwork: false

  # -- Use the host's pid namespace
  hostPID: false

  # -- Set image pull secrets
  imagePullSecrets: []

  # -- Set labels on the Pod. Pod-specific values will be merged with this.
  labels: {}

  # -- Node selection constraint
  # [[ref]](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)
  nodeSelector: {}

  # -- Custom priority class for different treatment by the scheduler
  priorityClassName: ""

  # -- Set Container restart policy.
  # @default -- `Always`. When `controller.type` is `cronjob` it defaults to `Never`.
  restartPolicy: ""

  # -- Allow specifying a runtimeClassName other than the default one (ie: nvidia)
  runtimeClassName: ""

  # -- Allows specifying a custom scheduler name
  schedulerName: ""

  # -- Configure the Security Context for the Pod
  securityContext:
    fsGroup: 65533

  # -- Duration in seconds the pod needs to terminate gracefully
  # -- [[ref](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#lifecycle)]
  terminationGracePeriodSeconds:

  # -- Specify taint tolerations
  # [[ref]](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
  tolerations: []

  # -- Defines topologySpreadConstraint rules.
  # [[ref]](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/)
  topologySpreadConstraints: []

controllers:
  main:
    # -- enable the controller.
    enabled: true
    type: job
    containers:
      main:
        dependsOn: ["gitsync"]
        image:
          # -- image repository
          repository: postgres
          # -- image tag
          tag: latest
          # -- image pull policy
          pullPolicy: IfNotPresent
        # -- Override the command(s) for the container
        command: 
        - /bin/sh
        - -c
        - |
          printenv
          sleep 5m
          psql postgres://$SUPERUSER:$PASSWORD@{{.Values.db.appName}}.{{.Values.db.namespace}}.svc.cluster.local/prowlarr-main -f /data/dump-k3s/dump_prowlarr
          psql postgres://$SUPERUSER:$PASSWORD@{{.Values.db.appName}}.{{.Values.db.namespace}}.svc.cluster.local/sonarr-main -f /data/dump-k3s/dump_sonarr
          psql postgres://$SUPERUSER:$PASSWORD@{{.Values.db.appName}}.{{.Values.db.namespace}}.svc.cluster.local/radarr-main -f /data/dump-k3s/dump_radarr
          psql postgres://$SUPERUSER:$PASSWORD@{{.Values.db.appName}}.{{.Values.db.namespace}}.svc.cluster.local/authentik -f /data/dump-k3s/dump_authentik
        env:
          SUPERUSER:
            valueFrom:
              secretKeyRef:
                name: superuser-secret
                key: username
          PASSWORD:
            valueFrom:
              secretKeyRef:
                name: superuser-secret
                key: password

      gitsync:
        dependsOn: []
        image:
          repository: ghcr.io/rdartus/git-sync@sha256
          tag: 1e73176654edc824de658a270582edd815ac7cb4bae06de96d8aadaebc900ac9
          # -- image pull policy
          pullPolicy: IfNotPresent
        args: 
          - --repo=git@gitlab.com:k3s-pi1/dump-k3s.git
          - --depth=1
          - --period=300s
          - --link=dump-k3s
          - --ref=main
          - --root=/data
          - --ssh-known-hosts=false
          - --ssh-key-file=/config/key
          - --git-LFS=true
          - --verbose=9
        env:
        securityContext:
          runAsUser: 65533

# @default -- See below
secrets:
  {}
configMaps:
  {}
configMapsFromFolderBasePath: null

# -- Configure the services for the chart here.
# Additional services can be added by adding a dictionary key similar to the 'main' service.
# @default -- See below
# service:
#   main:
  #   # -- Enables or disables the service
    # enabled: true

  #   # -- Override the name suffix that is used for this service
  #   nameOverride: ""

  #   # -- Configure which controller this service should target
    # controller: main

  #   # -- Make this the primary service for this controller (used in probes, notes, etc...).
  #   # If there is more than 1 service targeting the controller, make sure that only 1 service is
  #   # marked as primary.
    # primary: true

  #   # -- Set the service type
    # type: ClusterIP

  #   # -- Specify the internalTrafficPolicy for the service. Options: Cluster, Local
  #   # -- [[ref](https://kubernetes.io/docs/concepts/services-networking/service-traffic-policy/)]
  #   internalTrafficPolicy:

  #   # -- Specify the externalTrafficPolicy for the service. Options: Cluster, Local
  #   # -- [[ref](https://kubernetes.io/docs/tutorials/services/source-ip/)]
  #   externalTrafficPolicy:

  #   # -- Specify the ip policy. Options: SingleStack, PreferDualStack, RequireDualStack
  #   ipFamilyPolicy:
  #   # -- The ip families that should be used. Options: IPv4, IPv6
  #   ipFamilies: []

  #   # -- Provide additional annotations which may be required.
  #   annotations: {}

  #   # -- Provide additional labels which may be required.
  #   labels: {}

  #   # -- Allow adding additional match labels
  #   extraSelectorLabels: {}

  #   # -- Configure the Service port information here.
  #   # Additional ports can be added by adding a dictionary key similar to the 'http' service.
  #   # @default -- See below
  #   ports:
  #     http:
  #       # -- Enables or disables the port
  #       enabled: true

  #       # -- Make this the primary port (used in probes, notes, etc...)
  #       # If there is more than 1 service, make sure that only 1 port is marked as primary.
  #       primary: true

  #       # -- The port number
  #       port:

  #       # -- Port protocol.
  #       # Support values are `HTTP`, `HTTPS`, `TCP` and `UDP`.
  #       # HTTP and HTTPS spawn a TCP service and get used for internal URL and name generation
  #       protocol: HTTP

  #       # -- Specify a service targetPort if you wish to differ the service port from the application port.
  #       # If `targetPort` is specified, this port number is used in the container definition instead of
  #       # the `port` value. Therefore named ports are not supported for this field.
  #       targetPort:

  #       # -- Specify the nodePort value for the LoadBalancer and NodePort service types.
  #       # [[ref]](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
  #       nodePort:

  #       # -- Specify the appProtocol value for the Service.
  #       # [[ref]](https://kubernetes.io/docs/concepts/services-networking/service/#application-protocol)
  #       appProtocol:

# -- Configure the ingresses for the chart here.
ingress:
  {}

route:
  {}
persistence:
  config:
  #   # -- Enables or disables the persistence item. Defaults to true
    enabled: true

  #   # -- Sets the persistence type
  #   # Valid options are persistentVolumeClaim, emptyDir, nfs, hostPath, secret, configMap or custom
    type: secret
    name: ssh-secret
  data :
    enabled: true
    type: emptyDir

  
  #   # -- Storage Class for the config volume.
  #   # If set to `-`, dynamic provisioning is disabled.
  #   # If set to something else, the given storageClass is used.
  #   # If undefined (the default) or set to null, no storageClassName spec is set, choosing the default provisioner.
  #   storageClass: # "-"

  #   # -- If you want to reuse an existing claim, the name of the existing PVC can be passed here.
  #   existingClaim: # your-claim

  #   # -- The optional data source for the persistentVolumeClaim.
  #   # [[ref]](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-populators-and-data-sources)
  #   dataSource: {}

  #   # -- The optional volume populator for the persistentVolumeClaim.
  #   # [[ref]](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-populators-and-data-sources)
  #   dataSourceRef: {}

  #   # -- AccessMode for the persistent volume.
  #   # Make sure to select an access mode that is supported by your storage provider!
  #   # [[ref]](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
  #   accessMode: ReadWriteOnce

  #   # -- The amount of storage that is requested for the persistent volume.
  #   size: 1Gi

  #   # -- Set to true to retain the PVC upon `helm uninstall`
  #   retain: false

  #   # -- Configure mounts to all controllers and containers. By default the persistence item
  #   # will be mounted to `/<name_of_the_peristence_item>`.
  #   # Example:
  #   # globalMounts:
  #   #   - path: /config
  #   #     readOnly: false
  #   globalMounts: []

  #   # -- Explicitly configure mounts for specific controllers and containers.
  #   # Example:
  #   # advancedMounts:
  #   #   main: # the controller with the "main" identifier
  #   #     main: # the container with the "main" identifier
  #   #       - path: /data/config.yaml
  #   #         readOnly: true
  #   #         mountPropagation: None
  #   #         subPath: config.yaml
  #   #     second-container: # the container with the "second-container" identifier
  #   #       - path: /appdata/config
  #   #         readOnly: true
  #   #   second-controller: # the controller with the "second-controller" identifier
  #   #     main: # the container with the "main" identifier
  #   #       - path: /data/config.yaml
  #   #         readOnly: false
  #   #         subPath: config.yaml
  #   advancedMounts: {}

# -- Configure the networkPolicies for the chart here.
# Additional networkPolicies can be added by adding a dictionary key similar to the 'main' networkPolicy.
# @default -- See below
networkpolicies:
  {}
  # main:
  #   # -- Enables or disables the networkPolicy item. Defaults to true
  #   enabled: false

  #   # -- Configure which controller this networkPolicy should target
  #   controller: main

  #   # -- Define a custom podSelector for the networkPolicy. This takes precedence over targeting a controller.
  #   # podSelector: {}

  #   # -- The policyTypes for this networkPolicy
  #   policyTypes:
  #     - Ingress
  #     - Egress

  #   # -- The rulesets for this networkPolicy
  #   # [[ref]](https://kubernetes.io/docs/concepts/services-networking/network-policies/#networkpolicy-resource)
  #   rules:
  #     # -- The ingress rules for this networkPolicy. Allows all ingress traffic by default.
  #     ingress:
  #       - {}
  #     # -- The egress rules for this networkPolicy. Allows all egress traffic by default.
  #     egress:
  #       - {}

# -- Configure any unsupported raw resources here.
# @default -- See below
rawResources:
  {}
  # example:
  #   # -- Enables or disables the resource. Defaults to true
  #   enabled: false
  #   # -- Specify the apiVersion of the resource.
  #   apiVersion: v1
  #   # -- Specify the kind of the resource.
  #   kind: Endpoint
  #   # -- Override the name suffix that is used for this resource.
  #   nameOverride: ""
  #   # -- Provide additional annotations which may be required.
  #   annotations: {}
  #   # -- Provide additional labels which may be required.
  #   labels: {}
  #   # -- Configure the contents of the resource that is to be rendered.
  #   spec:

# -- Configure the Roles and Role Bindings for the chart here.
rbac:
  {}
  # roles:
  #   role1:
  #     # -- Force replace the name of the object.
  #     forceRename: <force name>
  #     # -- Enables or disables the Role. Can be templated.
  #     enabled: true
  #     # -- Set to Role,ClusterRole
  #     type: Role
  #     rules:
  #       - apiGroups: ["*"]
  #         resources: ["*"]
  #         verbs: ["get", "list", "watch"]
  # bindings:
  #   binding1:
  #     # -- Force replace the name of the object.
  #     forceRename: <force name>
  #     # -- Enables or disables the Role. Can be templated.
  #     enabled: true
  #     # -- Set to RoleBinding,ClusterRoleBinding
  #     type: RoleBinding
  #     # -- Can be an identifier of rbac.roles or a custom name and kind
  #     roleRef:
  #       name: test-role
  #       kind: Role
  #       identifier: test
  #     # -- If using an identifier it will be automatically filled, otherwise every key will need to be explicitly declared
  #     subjects:
  #       - identifier: default
  #       - kind: ServiceAccount
  #         name: test

{{- end }}
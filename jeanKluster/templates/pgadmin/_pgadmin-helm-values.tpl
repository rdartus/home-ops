{{- define "helmValues.pgadmin" }}

# Default values for pgAdmin4.
{{-  $dbServiceName := printf "%s.%s.svc.cluster.local" .Values.db.appName .Values.db.namespace -}}

replicaCount: 1

## pgAdmin4 container image
##
image:
  registry: docker.io
  repository: dpage/pgadmin4
  # Overrides the image tag whose default is the chart appVersion.
  tag: "8.2"
  pullPolicy: IfNotPresent

## Deployment annotations
annotations: {}

## priorityClassName
priorityClassName: ""

## Deployment entrypoint override
## Useful when there's a requirement to modify container's default:
## https://www.vaultproject.io/docs/platform/k8s/injector/examples#environment-variable-example
## ref: https://github.com/postgres/pgadmin4/blob/master/Dockerfile#L206
# command: "['/bin/sh', '-c', 'source /vault/secrets/config && <entrypoint script>']"

service:
  type: ClusterIP
  clusterIP: ""
  loadBalancerIP: ""
  port: 80
  targetPort: 80
  # targetPort: 4181 To be used with a proxy extraContainer
  portName: http

  annotations: {}
    ## Special annotations at the service level, e.g
    ## this will set vnet internal IP's rather than public ip's
    ## service.beta.kubernetes.io/azure-load-balancer-internal: "true"

  ## Specify the nodePort value for the service types.
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport
  ##
  # nodePort:

## Pod Service Account
## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
##
serviceAccount:
  # Specifies whether a service account should be created
  create: false
  # Annotations to add to the service account
  annotations: {}
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name: ""
  # Opt out of API credential automounting.
  # If you don't want the kubelet to automatically mount a ServiceAccount's API credentials,
  # you can opt out of the default behavior
  automountServiceAccountToken: false

## Strategy used to replace old Pods by new ones
## Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
##
strategy: {}
  # type: RollingUpdate
  # rollingUpdate:
  #   maxSurge: 0
  #   maxUnavailable: 1

## Server definitions will be loaded at launch time. This allows connection
## information to be pre-loaded into the instance of pgAdmin4 in the container.
## Ref: https://www.pgadmin.org/docs/pgadmin4/latest/import_export_servers.html
##
serverDefinitions:
  ## If true, server definitions will be created
  ##
  enabled: true

  ## The resource type to use for deploying server definitions.
  ## Can either be ConfigMap or Secret
  resourceType: ConfigMap

  servers:
    firstServer:
      Name: "CNPG"
      Group: "Servers"
      Port: 5432
      Username: "postgres"
      Host: "{{ $dbServiceName }}"
      SSLMode: "prefer"
      MaintenanceDB: "default"

networkPolicy:
  enabled: true

## Ingress
## Ref: https://kubernetes.io/docs/concepts/services-networking/ingress/
ingress:
  enabled: true
  annotations: 
    hajimari.io/enable: "true"
    hajimari.io/group: "Management"
    hajimari.io/icon: "database-edit"
  ingressClassName: traefik-ingresses
  hosts:
    - host: pgadmin.dartus.fr
      paths:
        - path: /
          pathType: Prefix
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local

# Additional config maps to be mounted inside a container
# Can be used to map config maps for sidecar as well
extraConfigmapMounts: []
  # - name: certs-configmap
  #   mountPath: /etc/ssl/certs
  #   subPath: ca-certificates.crt # (optional)
  #   configMap: certs-configmap
  #   readOnly: true

extraSecretMounts: []
  # - name: pgpassfile
  #   secret: pgpassfile
  #   subPath: pgpassfile
  #   mountPath: "/var/lib/pgadmin/storage/pgadmin/file.pgpass"
  #   readOnly: true

## Additional volumes to be mounted inside a container
##
extraVolumeMounts: []

## Specify additional containers in extraContainers.
## For example, to add an authentication proxy to a pgadmin4 pod.
extraContainers: |

# - name: proxy
#   image: quay.io/gambol99/keycloak-proxy:latest
#   args:
#   - -provider=github
#   - -client-id=
#   - -client-secret=
#   - -github-org=<ORG_NAME>
#   - -email-domain=*
#   - -cookie-secret=
#   - -http-address=http://0.0.0.0:4181
#   - -upstream-url=http://127.0.0.1:3000
#   ports:
#     - name: proxy-web
#       containerPort: 4181

## @param existingSecret Name of existing secret to use for default pgadmin credentials. `env.password` will be ignored and picked up from this secret.
##
existingSecret: "pgadmin-secret"
## @param secretKeys.pgadminPasswordKey Name of key in existing secret to use for default pgadmin credentials. Only used when `existingSecret` is set.
##
secretKeys:
  pgadminPasswordKey: password

## pgAdmin4 startup configuration
## Values in here get injected as environment variables
## Needed chart reinstall for apply changes
env:
  # can be email or nickname
  email: chart@domain.com
  # password: SuperSecret
  # pgpassfile: /var/lib/pgadmin/storage/pgadmin/file.pgpass

  # set context path for application (e.g. /pgadmin4/*)
  # contextPath: /pgadmin4

  ## If True, allows pgAdmin4 to create session cookies based on IP address
  ## Ref: https://www.pgadmin.org/docs/pgadmin4/latest/config_py.html
  ##
  enhanced_cookie_protection: "False"

  ## Add custom environment variables that will be injected to deployment
  ## Ref: https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html
  ##
  variables: []
  - name: PGADMIN_CONFIG_AUTHENTICATION_SOURCES
    value: "['oauth2', 'internal']"
  - name: PGADMIN_CONFIG_OAUTH2_CONFIG
    value: |
      [
      {
          # The name of the of the oauth provider, ex: github, google
          'OAUTH2_NAME': Authentik,
          # The display name, ex: Google
          'OAUTH2_DISPLAY_NAME': 'Authentik',
          # Oauth client id
          'OAUTH2_CLIENT_ID': None,
          # Oauth secret
          'OAUTH2_CLIENT_SECRET': None,
          # URL to generate a token,
          # Ex: https://github.com/login/oauth/access_token
          'OAUTH2_TOKEN_URL': None,
          # URL is used for authentication,
          # Ex: https://github.com/login/oauth/authorize
          'OAUTH2_AUTHORIZATION_URL': None,
          # server metadata url might optional for your provider
          'OAUTH2_SERVER_METADATA_URL': None,
          # Oauth base url, ex: https://api.github.com/
          'OAUTH2_API_BASE_URL': None,
          # Name of the Endpoint, ex: user
          'OAUTH2_USERINFO_ENDPOINT': None,
          # Oauth scope, ex: 'openid email profile'
          # Note that an 'email' claim is required in the resulting profile
          'OAUTH2_SCOPE': None,
          # The claim which is used for the username. If the value is empty the
          # email is used as username, but if a value is provided,
          # the claim has to exist.
          'OAUTH2_USERNAME_CLAIM': None,
          # Font-awesome icon, ex: fa-github
          'OAUTH2_ICON': None,
          # UI button colour, ex: #0000ff
          'OAUTH2_BUTTON_COLOR': None,
          # The additional claims to check on user ID Token or Userinfo response.
          # This is useful to provide additional authorization checks
          # before allowing access.
          # Example for GitLab: allowing all maintainers teams, and a specific
          # developers group to access pgadmin:
          # 'OAUTH2_ADDITIONAL_CLAIMS': {
          #     'https://gitlab.org/claims/groups/maintainer': [
          #           'kuberheads/applications',
          #           'kuberheads/dba',
          #           'kuberheads/support'
          #      ],
          #     'https://gitlab.org/claims/groups/developer': [
          #           'kuberheads/applications/team01'
          #      ],
          # }
          # Example for AzureAD:
          # 'OAUTH2_ADDITIONAL_CLAIMS': {
          #     'groups': ["0760b6cf-170e-4a14-91b3-4b78e0739963"],
          #     'wids': ["cf1c38e5-3621-4004-a7cb-879624dced7c"],
          # }
          'OAUTH2_ADDITIONAL_CLAIMS': None,
          # Set this variable to False to disable SSL certificate verification
          # for OAuth2 provider.
          # This may need to set False, in case of self-signed certificates.
          # Ref: https://github.com/psf/requests/issues/6071
          'OAUTH2_SSL_CERT_VERIFICATION': True
      }
      ]

  - name: PGADMIN_CONFIG_OAUTH2_AUTO_CREATE_USER
    value: true

## Additional environment variables from ConfigMaps
envVarsFromConfigMaps: []
  # - array-of
  # - config-map-names

## Additional environment variables from Secrets
envVarsFromSecrets: []
  # - array-of
  # - secret-names

persistentVolume:
  ## If true, pgAdmin4 will create/use a Persistent Volume Claim
  ## If false, use emptyDir
  ##
  enabled: true

  ## pgAdmin4 Persistent Volume Claim annotations
  ##
  annotations: {}

  ## pgAdmin4 Persistent Volume access modes
  ## Must match those of existing PV or dynamic provisioner
  ## Ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
  accessModes:
    - ReadWriteOnce

  ## pgAdmin4 Persistent Volume Size
  ##
  size: 200Mi

  ## pgAdmin4 Persistent Volume Storage Class
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  {{- if .Values.longhorn}}
  storageClass: longhorn
  {{- end}}
  # existingClaim: ""
  ## Sub-directory of the PV to mount
  # subPath: ""

## Additional volumes to be added to the deployment
##
extraVolumes: []

## Security context to be added to pgAdmin4 pods
##
securityContext:
  runAsUser: 5050
  runAsGroup: 5050
  fsGroup: 5050

containerSecurityContext:
  enabled: false
  allowPrivilegeEscalation: false

## pgAdmin4 readiness and liveness probe initial delay and timeout
## Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
##
livenessProbe:
  initialDelaySeconds: 30
  periodSeconds: 60
  timeoutSeconds: 15
  successThreshold: 1
  failureThreshold: 3

readinessProbe:
  initialDelaySeconds: 30
  periodSeconds: 60
  timeoutSeconds: 15
  successThreshold: 1
  failureThreshold: 3

## Required to be enabled pre pgAdmin4 4.16 release, to set the ACL on /var/lib/pgadmin.
## Ref: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
##
VolumePermissions:
  ## If true, enables an InitContainer to set permissions on /var/lib/pgadmin.
  ##
  enabled: false

## @param extraDeploy list of extra manifests to deploy
##
extraDeploy: []

## Additional InitContainers to initialize the pod
##
extraInitContainers: |

#   - name: add-folder-for-pgpass
#     image: "dpage/pgadmin4:latest"
#     command: ["/bin/mkdir", "-p", "/var/lib/pgadmin/storage/pgadmin"]
#     volumeMounts:
#       - name: pgadmin-data
#         mountPath: /var/lib/pgadmin
#     securityContext:
#       runAsUser: 5050

containerPorts:
  http: 80

resources: {}
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi

## Horizontal Pod Autoscaling
## ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
#
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80
  # targetMemoryUtilizationPercentage: 80

## Node labels for pgAdmin4 pod assignment
## Ref: https://kubernetes.io/docs/user-guide/node-selection/
##
nodeSelector: {}

## Node tolerations for server scheduling to nodes with taints
## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
##
tolerations: []

## Pod affinity
##
affinity: {}

## Pod annotations
##
podAnnotations: {}

## Pod labels
##
podLabels: {}
  # key1: value1
  # key2: value2

# -- The name of the Namespace to deploy
# If not set, `.Release.Namespace` is used
namespace: null

init:
  ## Init container resources
  ##
  resources: {}

## Define values for chart tests
test:
  ## Container image for test-connection.yaml
  image:
    registry: docker.io
    repository: busybox
    tag: latest
  ## Resources request/limit for test-connection Pod
  resources: {}
    # limits:
    #   cpu: 50m
    #   memory: 32Mi
    # requests:
    #   cpu: 25m
    #   memory: 16Mi
  ## Security context for test-connection Pod
  securityContext:
    runAsUser: 5051
    runAsGroup: 5051
    fsGroup: 5051
{{- end }}
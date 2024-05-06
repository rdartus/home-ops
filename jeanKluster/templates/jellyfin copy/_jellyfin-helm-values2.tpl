{{- define "helmValues.jellyfin2" }}

# Default values for jellyfin.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 1

image:
  repository: jellyfin/jellyfin
  tag: 10.7.5
  pullPolicy: IfNotPresent

nameOverride: ""
fullnameOverride: ""

podSecurityPolicy:
  create: false
  allowedHostPaths: []
#    - pathPrefix: "/mnt/Movies"

serviceAccount:
  create: false
  ## opt in/out of automounting API credentials into container
  ## https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
  automountToken: true

service:
  type: ClusterIP
  port: 8096
  ## Specify the nodePort value for the LoadBalancer and NodePort service types.
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport
  ##
  # nodePort:
  ## Provide any additional annotations which may be required. This can be used to
  ## set the LoadBalancer service type to internal only.
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer
  ##
  annotations: {}
  labels: {}
  ## Use loadBalancerIP to request a specific static IP,
  ## otherwise leave blank
  ##
  loadBalancerIP:
  # loadBalancerSourceRanges: []
  ## Set the externalTrafficPolicy in the Service to either Cluster or Local
  # externalTrafficPolicy: Cluster

env: {}

ingress:
  enabled: false
  commonAnnotations: {}
  ingresses: []
#    - name: "jellyfin-ingress-1"
#      annotations: {}
#      path: /
#      hosts: []
#        - "videos.pica.co.il"
#        - "videos.tatzan.com"
#      tls: []
#        - hosts:
#            - "*.pica.co.il"
#            - "*.tatzan.com"

persistence:
  config:
    enabled: false
    ## jellyfin configuration data Persistent Volume Storage Class
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
    ##   GKE, AWS & OpenStack)
    ##
#    storageClass: "local-storage"
    ##
    ## If you want to reuse an existing claim, you can pass the name of the PVC using
    ## the existingClaim variable
    # existingClaim: your-claim
    accessMode: ReadWriteOnce
    size: 1Gi
  media:
    enabled: false
    ## Directory where media is persisted
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
    ##   GKE, AWS & OpenStack)
    ##
    # storageClass: "-"
    ##
    ## If you want to reuse an existing claim, you can pass the name of the PVC using
    ## the existingClaim variable
    # existingClaim: your-claim
    # subPath: some-subpath
    accessMode: ReadWriteOnce
    size: 10Gi
  extraExistingClaimMounts: []
    # - name: external-mount
    #   mountPath: /srv/external-mount
    ## A manually managed Persistent Volume and Claim
    ## If defined, PVC must be created manually before volume will be bound
    #   existingClaim:
    #   readOnly: true

resources: {}
#  requests:
#    cpu: 1
#    memory: 1Gi
#  limits:
#    cpu: 4
#    memory: 4Gi

nodeSelector: {}

tolerations: []

affinity: {}

podAnnotations: {}

securityContext: {}

extraVolumes: []
#  - name: nas-movies
#    hostPath:
#      path: /mnt/Movies

extraVolumeMounts: []
#  - mountPath: /media/Movies
#    name: nas-movies
{{- end }}

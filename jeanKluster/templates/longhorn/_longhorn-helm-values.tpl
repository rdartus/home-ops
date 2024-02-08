{{- define "helmValues.longhorn" }}

# Default values for longhorn.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.
global:
  cattle:
    systemDefaultRegistry: ""
    windowsCluster:
      # Enable this to allow Longhorn to run on the Rancher deployed Windows cluster
      enabled: false
      # Tolerate Linux node taint
      tolerations:
      - key: "cattle.io/os"
        value: "linux"
        effect: "NoSchedule"
        operator: "Equal"
      # Select Linux nodes
      nodeSelector:
        kubernetes.io/os: "linux"
      # Recognize toleration and node selector for Longhorn run-time created components
      defaultSetting:
        taintToleration: cattle.io/os=linux:NoSchedule
        systemManagedComponentsNodeSelector: kubernetes.io/os:linux

networkPolicies:
  enabled: false
  # Available types: k3s, rke2, rke1
  type: "k3s"

image:
  longhorn:
    engine:
      repository: longhornio/longhorn-engine
      tag: v1.5.3
    manager:
      repository: longhornio/longhorn-manager
      tag: v1.5.3
    ui:
      repository: longhornio/longhorn-ui
      tag: v1.5.3
    instanceManager:
      repository: longhornio/longhorn-instance-manager
      tag: v1.5.3
    shareManager:
      repository: longhornio/longhorn-share-manager
      tag: v1.5.3
    backingImageManager:
      repository: longhornio/backing-image-manager
      tag: v1.5.3
    supportBundleKit:
      repository: longhornio/support-bundle-kit
      tag: v0.0.27
  csi:
    attacher:
      repository: longhornio/csi-attacher
      tag: v4.2.0
    provisioner:
      repository: longhornio/csi-provisioner
      tag: v3.4.1
    nodeDriverRegistrar:
      repository: longhornio/csi-node-driver-registrar
      tag: v2.7.0
    resizer:
      repository: longhornio/csi-resizer
      tag: v1.7.0
    snapshotter:
      repository: longhornio/csi-snapshotter
      tag: v6.2.1
    livenessProbe:
      repository: longhornio/livenessprobe
      tag: v2.9.0
  pullPolicy: IfNotPresent

service:
  ui:
    type: ClusterIP
    nodePort: null
  manager:
    type: ClusterIP
    nodePort: ""
    loadBalancerIP: ""
    loadBalancerSourceRanges: ""

persistence:
  defaultClass: true
  defaultFsType: ext4
  defaultMkfsParams: ""
  defaultClassReplicaCount: 3
  defaultDataLocality: disabled # best-effort otherwise
  reclaimPolicy: Delete
  migratable: false
  # -- Set NFS mount options for Longhorn StorageClass for RWX volumes
  nfsOptions: ""
  recurringJobSelector:
    enable: false
    jobList: []
  backingImage:
    enable: false
    name: ~
    dataSourceType: ~
    dataSourceParameters: ~
    expectedChecksum: ~
  defaultNodeSelector:
    enable: false # disable by default
    selector: ""
  removeSnapshotsDuringFilesystemTrim: ignored # "enabled" or "disabled" otherwise

helmPreUpgradeCheckerJob:
  enabled: false

csi:
  kubeletRootDir: ~
  attacherReplicaCount: ~
  provisionerReplicaCount: ~
  resizerReplicaCount: ~
  snapshotterReplicaCount: ~

defaultSettings:
  backupTarget: ~
  backupTargetCredentialSecret: ~
  allowRecurringJobWhileVolumeDetached: ~
  createDefaultDiskLabeledNodes: ~
  defaultDataPath: ~
  defaultDataLocality: ~
  replicaSoftAntiAffinity: true
  replicaAutoBalance: ~
  storageOverProvisioningPercentage: ~
  storageMinimalAvailablePercentage: ~
  storageReservedPercentageForDefaultDisk: ~
  upgradeChecker: ~
  defaultReplicaCount: 2
  defaultLonghornStaticStorageClass: ~
  backupstorePollInterval: ~
  failedBackupTTL: ~
  restoreVolumeRecurringJobs: ~
  recurringSuccessfulJobsHistoryLimit: ~
  recurringFailedJobsHistoryLimit: ~
  supportBundleFailedHistoryLimit: ~
  taintToleration: ~
  systemManagedComponentsNodeSelector: ~
  priorityClass: longhorn-critical
  autoSalvage: ~
  autoDeletePodWhenVolumeDetachedUnexpectedly: ~
  disableSchedulingOnCordonedNode: ~
  replicaZoneSoftAntiAffinity: ~
  nodeDownPodDeletionPolicy: ~
  nodeDrainPolicy: ~
  replicaReplenishmentWaitInterval: ~
  concurrentReplicaRebuildPerNodeLimit: ~
  concurrentVolumeBackupRestorePerNodeLimit: ~
  disableRevisionCounter: ~
  systemManagedPodsImagePullPolicy: ~
  allowVolumeCreationWithDegradedAvailability: ~
  autoCleanupSystemGeneratedSnapshot: ~
  concurrentAutomaticEngineUpgradePerNodeLimit: ~
  backingImageCleanupWaitInterval: ~
  backingImageRecoveryWaitInterval: ~
  guaranteedInstanceManagerCPU: ~
  kubernetesClusterAutoscalerEnabled: ~
  orphanAutoDeletion: ~
  storageNetwork: ~
  deletingConfirmationFlag: ~
  engineReplicaTimeout: ~
  snapshotDataIntegrity: ~
  snapshotDataIntegrityImmediateCheckAfterSnapshotCreation: ~
  snapshotDataIntegrityCronjob: ~
  removeSnapshotsDuringFilesystemTrim: ~
  fastReplicaRebuildEnabled: ~
  replicaFileSyncHttpClientTimeout: ~
  logLevel: ~
  backupCompressionMethod: ~
  backupConcurrentLimit: ~
  restoreConcurrentLimit: ~
  v2DataEngine: ~
  offlineReplicaRebuilding: ~
  disableSnapshotPurge: ~
  allowCollectingLonghornUsageMetrics: ~

privateRegistry:
  createSecret: ~
  registryUrl: ~
  registryUser: ~
  registryPasswd: ~
  registrySecret: ~

longhornManager:
  log:
    ## Allowed values are `plain` or `json`.
    format: plain
  priorityClass: ~
  tolerations: []
  ## If you want to set tolerations for Longhorn Manager DaemonSet, delete the `[]` in the line above
  ## and uncomment this example block
  # - key: "key"
  #   operator: "Equal"
  #   value: "value"
  #   effect: "NoSchedule"
  nodeSelector: {}
  ## If you want to set node selector for Longhorn Manager DaemonSet, delete the `{}` in the line above
  ## and uncomment this example block
  #  label-key1: "label-value1"
  #  label-key2: "label-value2"
  serviceAnnotations: {}
  ## If you want to set annotations for the Longhorn Manager service, delete the `{}` in the line above
  ## and uncomment this example block
  #  annotation-key1: "annotation-value1"
  #  annotation-key2: "annotation-value2"

longhornDriver:
  priorityClass: ~
  tolerations: []
  ## If you want to set tolerations for Longhorn Driver Deployer Deployment, delete the `[]` in the line above
  ## and uncomment this example block
  # - key: "key"
  #   operator: "Equal"
  #   value: "value"
  #   effect: "NoSchedule"
  nodeSelector: {}
  ## If you want to set node selector for Longhorn Driver Deployer Deployment, delete the `{}` in the line above
  ## and uncomment this example block
  #  label-key1: "label-value1"
  #  label-key2: "label-value2"

longhornUI:
  replicas: 2
  priorityClass: ~
  tolerations: []
  ## If you want to set tolerations for Longhorn UI Deployment, delete the `[]` in the line above
  ## and uncomment this example block
  # - key: "key"
  #   operator: "Equal"
  #   value: "value"
  #   effect: "NoSchedule"
  nodeSelector: {}
  ## If you want to set node selector for Longhorn UI Deployment, delete the `{}` in the line above
  ## and uncomment this example block
  #  label-key1: "label-value1"
  #  label-key2: "label-value2"

ingress:
  ## Set to true to enable ingress record generation
  enabled: true

  ## Add ingressClassName to the Ingress
  ## Can replace the kubernetes.io/ingress.class annotation on v1.18+
  ingressClassName: ~

  host: longhorn.dartus.fr

  ## Set this to true in order to enable TLS on the ingress record
  tls: false

  ## Enable this in order to enable that the backend service will be connected at port 443
  secureBackends: false

  ## If TLS is set to true, you must declare what secret will store the key/certificate for TLS
  tlsSecret: longhorn.local-tls

  ## If ingress is enabled you can set the default ingress path
  path: /

  ## Ingress annotations done as key:value pairs
  ## If you're using kube-lego, you will want to add:
  ## kubernetes.io/tls-acme: true
  ##
  ## For a full list of possible ingress annotations, please see
  ## ref: https://github.com/kubernetes/ingress-nginx/blob/master/docs/annotations.md
  ##
  ## If tls is set to true, annotation ingress.kubernetes.io/secure-backends: "true" will automatically be set
  annotations:
    hajimari.io/enable: "true"
    hajimari.io/group: "Management"
    hajimari.io/icon: "cow"

  secrets:
  ## If you're providing your own certificates, please use this to add the certificates as secrets
  ## key and certificate should start with -----BEGIN CERTIFICATE----- or
  ## -----BEGIN RSA PRIVATE KEY-----
  ##
  ## name should line up with a tlsSecret set further up
  ## If you're using kube-lego, this is unneeded, as it will create the secret for you if it is not set
  ##
  ## It is also possible to create and manage the certificates outside of this helm chart
  ## Please see README.md for more information
  # - name: longhorn.local-tls
  #   key:
  #   certificate:

#  For Kubernetes < v1.25, if your cluster enables Pod Security Policy admission controller,
#  set this to `true` to ship longhorn-psp which allow privileged Longhorn pods to start
enablePSP: false

## Specify override namespace, specifically this is useful for using longhorn as sub-chart
## and its release namespace is not the `longhorn-system`
namespaceOverride: ""

# Annotations to add to the Longhorn Manager DaemonSet Pods. Optional.
annotations: {}

serviceAccount:
  # Annotations to add to the service account
  annotations: {}

{{- end }}
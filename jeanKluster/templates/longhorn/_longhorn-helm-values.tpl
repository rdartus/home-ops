{{- define "helmValues.longhorn" }}
# Default values for longhorn.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.
global:
  cattle:
    # -- Default system registry.
    systemDefaultRegistry: ""
    windowsCluster:
      # -- Setting that allows Longhorn to run on a Rancher Windows cluster.
      enabled: false
      # -- Toleration for Linux nodes that can run user-deployed Longhorn components.
      tolerations:
      - key: "cattle.io/os"
        value: "linux"
        effect: "NoSchedule"
        operator: "Equal"
      # -- Node selector for Linux nodes that can run user-deployed Longhorn components.
      nodeSelector:
        kubernetes.io/os: "linux"
      defaultSetting:
        # -- Toleration for system-managed Longhorn components.
        taintToleration: cattle.io/os=linux:NoSchedule
        # -- Node selector for system-managed Longhorn components.
        systemManagedComponentsNodeSelector: kubernetes.io/os:linux

networkPolicies:
  # -- Setting that allows you to enable network policies that control access to Longhorn pods.
  enabled: false
  # -- Distribution that determines the policy for allowing access for an ingress. (Options: "k3s", "rke2", "rke1")
  type: "k3s"

image:
  longhorn:
    engine:
      # -- Repository for the Longhorn Engine image.
      repository: longhornio/longhorn-engine
      # -- Specify Longhorn engine image tag
      tag: v1.6.0
    manager:
      # -- Repository for the Longhorn Manager image.
      repository: longhornio/longhorn-manager
      # -- Specify Longhorn manager image tag
      tag: v1.6.0
    ui:
      # -- Repository for the Longhorn UI image.
      repository: longhornio/longhorn-ui
      # -- Specify Longhorn ui image tag
      tag: v1.6.0
    instanceManager:
      # -- Repository for the Longhorn Instance Manager image.
      repository: longhornio/longhorn-instance-manager
      # -- Specify Longhorn instance manager image tag
      tag: v1.6.0
    shareManager:
      # -- Repository for the Longhorn Share Manager image.
      repository: longhornio/longhorn-share-manager
      # -- Specify Longhorn share manager image tag
      tag: v1.6.0
    backingImageManager:
      # -- Repository for the Backing Image Manager image. When unspecified, Longhorn uses the default value.
      repository: longhornio/backing-image-manager
      # -- Specify Longhorn backing image manager image tag
      tag: v1.6.0
    supportBundleKit:
      # -- Repository for the Longhorn Support Bundle Manager image.
      repository: longhornio/support-bundle-kit
      # -- Tag for the Longhorn Support Bundle Manager image.
      tag: v0.0.33
  csi:
    attacher:
      # -- Repository for the CSI attacher image. When unspecified, Longhorn uses the default value.
      repository: longhornio/csi-attacher
      # -- Tag for the CSI attacher image. When unspecified, Longhorn uses the default value.
      tag: v4.4.2
    provisioner:
      # -- Repository for the CSI Provisioner image. When unspecified, Longhorn uses the default value.
      repository: longhornio/csi-provisioner
      # -- Tag for the CSI Provisioner image. When unspecified, Longhorn uses the default value.
      tag: v3.6.2
    nodeDriverRegistrar:
      # -- Repository for the CSI Node Driver Registrar image. When unspecified, Longhorn uses the default value.
      repository: longhornio/csi-node-driver-registrar
      # -- Tag for the CSI Node Driver Registrar image. When unspecified, Longhorn uses the default value.
      tag: v2.9.2
    resizer:
      # -- Repository for the CSI Resizer image. When unspecified, Longhorn uses the default value.
      repository: longhornio/csi-resizer
      # -- Tag for the CSI Resizer image. When unspecified, Longhorn uses the default value.
      tag: v1.9.2
    snapshotter:
      # -- Repository for the CSI Snapshotter image. When unspecified, Longhorn uses the default value.
      repository: longhornio/csi-snapshotter
      # -- Tag for the CSI Snapshotter image. When unspecified, Longhorn uses the default value.
      tag: v6.3.2
    livenessProbe:
      # -- Repository for the CSI liveness probe image. When unspecified, Longhorn uses the default value.
      repository: longhornio/livenessprobe
      # -- Tag for the CSI liveness probe image. When unspecified, Longhorn uses the default value.
      tag: v2.11.0
  openshift:
    oauthProxy:
      # -- Repository for the OAuth Proxy image. This setting applies only to OpenShift users.
      repository: quay.io/openshift/origin-oauth-proxy
      # -- Tag for the OAuth Proxy image. This setting applies only to OpenShift users. Specify OCP/OKD version 4.1 or later. The latest stable version is 4.14.
      tag: 4.14
  # -- Image pull policy that applies to all user-deployed Longhorn components, such as Longhorn Manager, Longhorn driver, and Longhorn UI.
  pullPolicy: IfNotPresent

service:
  ui:
    # -- Service type for Longhorn UI. (Options: "ClusterIP", "NodePort", "LoadBalancer", "Rancher-Proxy")
    type: ClusterIP
    # -- NodePort port number for Longhorn UI. When unspecified, Longhorn selects a free port between 30000 and 32767.
    nodePort: null
  manager:
    # -- Service type for Longhorn Manager.
    type: ClusterIP
    # -- NodePort port number for Longhorn Manager. When unspecified, Longhorn selects a free port between 30000 and 32767.
    nodePort: ""

persistence:
  # -- Setting that allows you to specify the default Longhorn StorageClass.
  defaultClass: true
  # -- Filesystem type of the default Longhorn StorageClass.
  defaultFsType: ext4
  # -- mkfs parameters of the default Longhorn StorageClass.
  defaultMkfsParams: ""
  # -- Replica count of the default Longhorn StorageClass.
  defaultClassReplicaCount: 3
  # -- Data locality of the default Longhorn StorageClass. (Options: "disabled", "best-effort")
  defaultDataLocality: disabled
  # -- Reclaim policy that provides instructions for handling of a volume after its claim is released. (Options: "Retain", "Delete")
  reclaimPolicy: Delete
  # -- Setting that allows you to enable live migration of a Longhorn volume from one node to another.
  migratable: false
  # -- Set NFS mount options for Longhorn StorageClass for RWX volumes
  nfsOptions: ""
  recurringJobSelector:
    # -- Setting that allows you to enable the recurring job selector for a Longhorn StorageClass.
    enable: false
    # -- Recurring job selector for a Longhorn StorageClass. Ensure that quotes are used correctly when specifying job parameters. (Example: `[{"name":"backup", "isGroup":true}]`)
    jobList: []
  backingImage:
    # -- Setting that allows you to use a backing image in a Longhorn StorageClass.
    enable: false
    # -- Backing image to be used for creating and restoring volumes in a Longhorn StorageClass. When no backing images are available, specify the data source type and parameters that Longhorn can use to create a backing image.
    name: ~
    # -- Data source type of a backing image used in a Longhorn StorageClass.
    # If the backing image exists in the cluster, Longhorn uses this setting to verify the image.
    # If the backing image does not exist, Longhorn creates one using the specified data source type.
    dataSourceType: ~
    # -- Data source parameters of a backing image used in a Longhorn StorageClass.
    # You can specify a JSON string of a map. (Example: `'{\"url\":\"https://backing-image-example.s3-region.amazonaws.com/test-backing-image\"}'`)
    dataSourceParameters: ~
    # -- Expected SHA-512 checksum of a backing image used in a Longhorn StorageClass.
    expectedChecksum: ~
  defaultNodeSelector:
    # -- Setting that allows you to enable the node selector for the default Longhorn StorageClass.
    enable: false
    # -- Node selector for the default Longhorn StorageClass. Longhorn uses only nodes with the specified tags for storing volume data. (Examples: "storage,fast")
    selector: ""
  # -- Setting that allows you to enable automatic snapshot removal during filesystem trim for a Longhorn StorageClass. (Options: "ignored", "enabled", "disabled")
  removeSnapshotsDuringFilesystemTrim: ignored

preUpgradeChecker:
  # -- Setting that allows Longhorn to perform pre-upgrade checks. Disable this setting when installing Longhorn using Argo CD or other GitOps solutions.
  jobEnabled: false
  # -- Setting that allows Longhorn to perform upgrade version checks after starting the Longhorn Manager DaemonSet Pods. Disabling this setting also disables `preUpgradeChecker.jobEnabled`. Longhorn recommends keeping this setting enabled.
  upgradeVersionCheck: true

csi:
  # -- kubelet root directory. When unspecified, Longhorn uses the default value.
  kubeletRootDir: ~
  # -- Replica count of the CSI Attacher. When unspecified, Longhorn uses the default value ("3").
  attacherReplicaCount: ~
  # -- Replica count of the CSI Provisioner. When unspecified, Longhorn uses the default value ("3").
  provisionerReplicaCount: ~
  # -- Replica count of the CSI Resizer. When unspecified, Longhorn uses the default value ("3").
  resizerReplicaCount: ~
  # -- Replica count of the CSI Snapshotter. When unspecified, Longhorn uses the default value ("3").
  snapshotterReplicaCount: ~

defaultSettings:
  # -- Endpoint used to access the backupstore. (Options: "NFS", "CIFS", "AWS", "GCP", "AZURE")
  backupTarget: ~
  # -- Name of the Kubernetes secret associated with the backup target.
  backupTargetCredentialSecret: ~
  # -- Setting that allows Longhorn to automatically attach a volume and create snapshots or backups when recurring jobs are run.
  allowRecurringJobWhileVolumeDetached: ~
  # -- Setting that allows Longhorn to automatically create a default disk only on nodes with the label "node.longhorn.io/create-default-disk=true" (if no other disks exist). When this setting is disabled, Longhorn creates a default disk on each node that is added to the cluster.
  createDefaultDiskLabeledNodes: ~
  # -- Default path for storing data on a host. The default value is "/var/lib/longhorn/".
  defaultDataPath: ~
  # -- Default data locality. A Longhorn volume has data locality if a local replica of the volume exists on the same node as the pod that is using the volume.
  defaultDataLocality: ~
  # -- Setting that allows scheduling on nodes with healthy replicas of the same volume. This setting is disabled by default.
  replicaSoftAntiAffinity: true
  # -- Setting that automatically rebalances replicas when an available node is discovered.
  replicaAutoBalance: ~
  # -- Percentage of storage that can be allocated relative to hard drive capacity. The default value is "100".
  storageOverProvisioningPercentage: ~
  # -- Percentage of minimum available disk capacity. When the minimum available capacity exceeds the total available capacity, the disk becomes unschedulable until more space is made available for use. The default value is "25".
  storageMinimalAvailablePercentage: ~
  # -- Percentage of disk space that is not allocated to the default disk on each new Longhorn node.
  storageReservedPercentageForDefaultDisk: ~
  # -- Upgrade Checker that periodically checks for new Longhorn versions. When a new version is available, a notification appears on the Longhorn UI. This setting is enabled by default
  upgradeChecker: ~
  # -- Default number of replicas for volumes created using the Longhorn UI. For Kubernetes configuration, modify the `numberOfReplicas` field in the StorageClass. The default value is "3".
  defaultReplicaCount: 2
  # -- Default Longhorn StorageClass. "storageClassName" is assigned to PVs and PVCs that are created for an existing Longhorn volume. "storageClassName" can also be used as a label, so it is possible to use a Longhorn StorageClass to bind a workload to an existing PV without creating a Kubernetes StorageClass object. The default value is "longhorn-static".
  defaultLonghornStaticStorageClass: ~
  # -- Number of seconds that Longhorn waits before checking the backupstore for new backups. The default value is "300". When the value is "0", polling is disabled.
  backupstorePollInterval: ~
  # -- Number of minutes that Longhorn keeps a failed backup resource. When the value is "0", automatic deletion is disabled.
  failedBackupTTL: ~
  # -- Setting that restores recurring jobs from a backup volume on a backup target and creates recurring jobs if none exist during backup restoration.
  restoreVolumeRecurringJobs: ~
  # -- Maximum number of successful recurring backup and snapshot jobs to be retained. When the value is "0", a history of successful recurring jobs is not retained.
  recurringSuccessfulJobsHistoryLimit: ~
  # -- Maximum number of failed recurring backup and snapshot jobs to be retained. When the value is "0", a history of failed recurring jobs is not retained.
  recurringFailedJobsHistoryLimit: ~
  # -- Maximum number of snapshots or backups to be retained.
  recurringJobMaxRetention: ~
  # -- Maximum number of failed support bundles that can exist in the cluster. When the value is "0", Longhorn automatically purges all failed support bundles.
  supportBundleFailedHistoryLimit: ~
  # -- Taint or toleration for system-managed Longhorn components.
  taintToleration: ~
  # -- Node selector for system-managed Longhorn components.
  systemManagedComponentsNodeSelector: ~
  # -- PriorityClass for system-managed Longhorn components.
  # This setting can help prevent Longhorn components from being evicted under Node Pressure.
  # Notice that this will be applied to Longhorn user-deployed components by default if there are no priority class values set yet, such as `longhornManager.priorityClass`.
  priorityClass: &defaultPriorityClassNameRef "longhorn-critical"
  # -- Setting that allows Longhorn to automatically salvage volumes when all replicas become faulty (for example, when the network connection is interrupted). Longhorn determines which replicas are usable and then uses these replicas for the volume. This setting is enabled by default.
  autoSalvage: ~
  # -- Setting that allows Longhorn to automatically delete a workload pod that is managed by a controller (for example, daemonset) whenever a Longhorn volume is detached unexpectedly (for example, during Kubernetes upgrades). After deletion, the controller restarts the pod and then Kubernetes handles volume reattachment and remounting.
  autoDeletePodWhenVolumeDetachedUnexpectedly: ~
  # -- Setting that prevents Longhorn Manager from scheduling replicas on a cordoned Kubernetes node. This setting is enabled by default.
  disableSchedulingOnCordonedNode: ~
  # -- Setting that allows Longhorn to schedule new replicas of a volume to nodes in the same zone as existing healthy replicas. Nodes that do not belong to any zone are treated as existing in the zone that contains healthy replicas. When identifying zones, Longhorn relies on the label "topology.kubernetes.io/zone=<Zone name of the node>" in the Kubernetes node object.
  replicaZoneSoftAntiAffinity: ~
  # -- Setting that allows scheduling on disks with existing healthy replicas of the same volume. This setting is enabled by default.
  replicaDiskSoftAntiAffinity: ~
  # -- Policy that defines the action Longhorn takes when a volume is stuck with a StatefulSet or Deployment pod on a node that failed.
  nodeDownPodDeletionPolicy: ~
  # -- Policy that defines the action Longhorn takes when a node with the last healthy replica of a volume is drained.
  nodeDrainPolicy: ~
  # -- Setting that allows automatic detaching of manually-attached volumes when a node is cordoned.
  detachManuallyAttachedVolumesWhenCordoned: ~
  # -- Number of seconds that Longhorn waits before reusing existing data on a failed replica instead of creating a new replica of a degraded volume.
  replicaReplenishmentWaitInterval: ~
  # -- Maximum number of replicas that can be concurrently rebuilt on each node.
  concurrentReplicaRebuildPerNodeLimit: ~
  # -- Maximum number of volumes that can be concurrently restored on each node using a backup. When the value is "0", restoration of volumes using a backup is disabled.
  concurrentVolumeBackupRestorePerNodeLimit: ~
  # -- Setting that disables the revision counter and thereby prevents Longhorn from tracking all write operations to a volume. When salvaging a volume, Longhorn uses properties of the "volume-head-xxx.img" file (the last file size and the last time the file was modified) to select the replica to be used for volume recovery. This setting applies only to volumes created using the Longhorn UI.
  disableRevisionCounter: ~
  # -- Image pull policy for system-managed pods, such as Instance Manager, engine images, and CSI Driver. Changes to the image pull policy are applied only after the system-managed pods restart.
  systemManagedPodsImagePullPolicy: ~
  # -- Setting that allows you to create and attach a volume without having all replicas scheduled at the time of creation.
  allowVolumeCreationWithDegradedAvailability: ~
  # -- Setting that allows Longhorn to automatically clean up the system-generated snapshot after replica rebuilding is completed.
  autoCleanupSystemGeneratedSnapshot: ~
  # -- Setting that allows Longhorn to automatically clean up the snapshot generated by a recurring backup job.
  autoCleanupRecurringJobBackupSnapshot: ~
  # -- Maximum number of engines that are allowed to concurrently upgrade on each node after Longhorn Manager is upgraded. When the value is "0", Longhorn does not automatically upgrade volume engines to the new default engine image version.
  concurrentAutomaticEngineUpgradePerNodeLimit: ~
  # -- Number of minutes that Longhorn waits before cleaning up the backing image file when no replicas in the disk are using it.
  backingImageCleanupWaitInterval: ~
  # -- Number of seconds that Longhorn waits before downloading a backing image file again when the status of all image disk files changes to "failed" or "unknown".
  backingImageRecoveryWaitInterval: ~
  # -- Percentage of the total allocatable CPU resources on each node to be reserved for each instance manager pod when the V1 Data Engine is enabled. The default value is "12".
  guaranteedInstanceManagerCPU: ~
  # -- Setting that notifies Longhorn that the cluster is using the Kubernetes Cluster Autoscaler.
  kubernetesClusterAutoscalerEnabled: ~
  # -- Setting that allows Longhorn to automatically delete an orphaned resource and the corresponding data (for example, stale replicas). Orphaned resources on failed or unknown nodes are not automatically cleaned up.
  orphanAutoDeletion: ~
  # -- Storage network for in-cluster traffic. When unspecified, Longhorn uses the Kubernetes cluster network.
  storageNetwork: ~
  # -- Flag that prevents accidental uninstallation of Longhorn.
  deletingConfirmationFlag: ~
  # -- Timeout between the Longhorn Engine and replicas. Specify a value between "8" and "30" seconds. The default value is "8".
  engineReplicaTimeout: ~
  # -- Setting that allows you to enable and disable snapshot hashing and data integrity checks.
  snapshotDataIntegrity: ~
  # -- Setting that allows disabling of snapshot hashing after snapshot creation to minimize impact on system performance.
  snapshotDataIntegrityImmediateCheckAfterSnapshotCreation: ~
  # -- Setting that defines when Longhorn checks the integrity of data in snapshot disk files. You must use the Unix cron expression format.
  snapshotDataIntegrityCronjob: ~
  # -- Setting that allows Longhorn to automatically mark the latest snapshot and its parent files as removed during a filesystem trim. Longhorn does not remove snapshots containing multiple child files.
  removeSnapshotsDuringFilesystemTrim: ~
  # -- Setting that allows fast rebuilding of replicas using the checksum of snapshot disk files. Before enabling this setting, you must set the snapshot-data-integrity value to "enable" or "fast-check".
  fastReplicaRebuildEnabled: ~
  # -- Number of seconds that an HTTP client waits for a response from a File Sync server before considering the connection to have failed.
  replicaFileSyncHttpClientTimeout: ~
  # -- Log levels that indicate the type and severity of logs in Longhorn Manager. The default value is "Info". (Options: "Panic", "Fatal", "Error", "Warn", "Info", "Debug", "Trace")
  logLevel: ~
  # -- Setting that allows you to specify a backup compression method.
  backupCompressionMethod: ~
  # -- Maximum number of worker threads that can concurrently run for each backup.
  backupConcurrentLimit: ~
  # -- Maximum number of worker threads that can concurrently run for each restore operation.
  restoreConcurrentLimit: ~
  # -- Setting that allows you to enable the V1 Data Engine.
  v1DataEngine: ~
  # -- Setting that allows you to enable the V2 Data Engine, which is based on the Storage Performance Development Kit (SPDK). The V2 Data Engine is a preview feature and should not be used in production environments.
  v2DataEngine: ~
  # -- Setting that allows you to configure maximum huge page size (in MiB) for the V2 Data Engine.
  v2DataEngineHugepageLimit: ~
  # -- Setting that allows rebuilding of offline replicas for volumes using the V2 Data Engine.
  offlineReplicaRebuilding: ~
  # -- Number of millicpus on each node to be reserved for each Instance Manager pod when the V2 Data Engine is enabled. The default value is "1250".
  v2DataEngineGuaranteedInstanceManagerCPU: ~
  # -- Setting that allows scheduling of empty node selector volumes to any node.
  allowEmptyNodeSelectorVolume: ~
  # -- Setting that allows scheduling of empty disk selector volumes to any disk.
  allowEmptyDiskSelectorVolume: ~
  # -- Setting that allows Longhorn to periodically collect anonymous usage data for product improvement purposes. Longhorn sends collected data to the [Upgrade Responder](https://github.com/longhorn/upgrade-responder) server, which is the data source of the Longhorn Public Metrics Dashboard (https://metrics.longhorn.io). The Upgrade Responder server does not store data that can be used to identify clients, including IP addresses.
  allowCollectingLonghornUsageMetrics: ~
  # -- Setting that temporarily prevents all attempts to purge volume snapshots.
  disableSnapshotPurge: ~

privateRegistry:
  # -- Setting that allows you to create a private registry secret.
  createSecret: ~
  # -- URL of a private registry. When unspecified, Longhorn uses the default system registry.
  registryUrl: ~
  # -- User account used for authenticating with a private registry.
  registryUser: ~
  # -- Password for authenticating with a private registry.
  registryPasswd: ~
  # -- Kubernetes secret that allows you to pull images from a private registry. This setting applies only when creation of private registry secrets is enabled. You must include the private registry name in the secret name.
  registrySecret: ~

longhornManager:
  log:
    # -- Format of Longhorn Manager logs. (Options: "plain", "json")
    format: plain
  # -- PriorityClass for Longhorn Manager.
  priorityClass: *defaultPriorityClassNameRef
  # -- Toleration for Longhorn Manager on nodes allowed to run Longhorn Manager.
  tolerations: []
  ## If you want to set tolerations for Longhorn Manager DaemonSet, delete the `[]` in the line above
  ## and uncomment this example block
  # - key: "key"
  #   operator: "Equal"
  #   value: "value"
  #   effect: "NoSchedule"
  # -- Node selector for Longhorn Manager. Specify the nodes allowed to run Longhorn Manager.
  nodeSelector: {}
  ## If you want to set node selector for Longhorn Manager DaemonSet, delete the `{}` in the line above
  ## and uncomment this example block
  #  label-key1: "label-value1"
  #  label-key2: "label-value2"
  # -- Annotation for the Longhorn Manager service.
  serviceAnnotations: {}
  ## If you want to set annotations for the Longhorn Manager service, delete the `{}` in the line above
  ## and uncomment this example block
  #  annotation-key1: "annotation-value1"
  #  annotation-key2: "annotation-value2"

longhornDriver:
  # -- PriorityClass for Longhorn Driver.
  priorityClass: *defaultPriorityClassNameRef
  # -- Toleration for Longhorn Driver on nodes allowed to run Longhorn components.
  tolerations: []
  ## If you want to set tolerations for Longhorn Driver Deployer Deployment, delete the `[]` in the line above
  ## and uncomment this example block
  # - key: "key"
  #   operator: "Equal"
  #   value: "value"
  #   effect: "NoSchedule"
  # -- Node selector for Longhorn Driver. Specify the nodes allowed to run Longhorn Driver.
  nodeSelector: {}
  ## If you want to set node selector for Longhorn Driver Deployer Deployment, delete the `{}` in the line above
  ## and uncomment this example block
  #  label-key1: "label-value1"
  #  label-key2: "label-value2"

longhornUI:
  # -- Replica count for Longhorn UI.
  replicas: 2
  # -- PriorityClass for Longhorn UI.
  priorityClass: *defaultPriorityClassNameRef
  # -- Toleration for Longhorn UI on nodes allowed to run Longhorn components.
  tolerations: []
  ## If you want to set tolerations for Longhorn UI Deployment, delete the `[]` in the line above
  ## and uncomment this example block
  # - key: "key"
  #   operator: "Equal"
  #   value: "value"
  #   effect: "NoSchedule"
  # -- Node selector for Longhorn UI. Specify the nodes allowed to run Longhorn UI.
  nodeSelector: {}
  ## If you want to set node selector for Longhorn UI Deployment, delete the `{}` in the line above
  ## and uncomment this example block
  #  label-key1: "label-value1"
  #  label-key2: "label-value2"

ingress:
  # -- Setting that allows Longhorn to generate ingress records for the Longhorn UI service.
  enabled: true

  # -- IngressClass resource that contains ingress configuration, including the name of the Ingress controller.
  # ingressClassName can replace the kubernetes.io/ingress.class annotation used in earlier Kubernetes releases.
  ingressClassName: ~

  # -- Hostname of the Layer 7 load balancer.
  host: longhorn<dqrtus<fr

  # -- Setting that allows you to enable TLS on ingress records.
  tls: false

  # -- Setting that allows you to enable secure connections to the Longhorn UI service via port 443.
  secureBackends: false

  # -- TLS secret that contains the private key and certificate to be used for TLS. This setting applies only when TLS is enabled on ingress records.
  tlsSecret: longhorn.local-tls

  # -- Default ingress path. You can access the Longhorn UI by following the full ingress path 
  path: /

  ## If you're using kube-lego, you will want to add:
  ## kubernetes.io/tls-acme: true
  ##
  ## For a full list of possible ingress annotations, please see
  ## ref: https://github.com/kubernetes/ingress-nginx/blob/master/docs/annotations.md
  ##
  ## If tls is set to true, annotation ingress.kubernetes.io/secure-backends: "true" will automatically be set
  # -- Ingress annotations in the form of key-value pairs.
  annotations:
  #  kubernetes.io/ingress.class: nginx
  #  kubernetes.io/tls-acme: true

  # -- Secret that contains a TLS private key and certificate. Use secrets if you want to use your own certificates to secure ingresses.
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

# -- Setting that allows you to enable pod security policies (PSPs) that allow privileged Longhorn pods to start. This setting applies only to clusters running Kubernetes 1.25 and earlier, and with the built-in Pod Security admission controller enabled.
enablePSP: false

# -- Specify override namespace, specifically this is useful for using longhorn as sub-chart and its release namespace is not the `longhorn-system`.
namespaceOverride: ""

# -- Annotation for the Longhorn Manager DaemonSet pods. This setting is optional.
annotations: {}

serviceAccount:
  # -- Annotations to add to the service account
  annotations: {}

metrics:
  serviceMonitor:
    # -- Setting that allows the creation of a Prometheus ServiceMonitor resource for Longhorn Manager components.
    enabled: false

## openshift settings
openshift:
  # -- Setting that allows Longhorn to integrate with OpenShift.
  enabled: false
  ui:
    # -- Route for connections between Longhorn and the OpenShift web console.
    route: "longhorn-ui"
    # -- Port for accessing the OpenShift web console.
    port: 443
    # -- Port for proxy that provides access to the OpenShift web console.
    proxy: 8443

# -- Setting that allows Longhorn to generate code coverage profiles.
enableGoCoverDir: false

{{- end }}
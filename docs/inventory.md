# Inventaire du dépôt et du cluster

## Dépôt

| Chemin | Contenu |
| --- | --- |
| `kubernetes/_archive/` | Applications et variantes retirées de la réconciliation active |
| `kubernetes/apps/` | Applications et services actifs, regroupés par namespace |
| `kubernetes/components/` | Composants Kustomize partagés |
| `kubernetes/flux/` | Bootstrap du cluster, métadonnées de sources et `cluster-meta`/`cluster-apps` |
| `talos/` | Configuration du cluster Talos et secrets chiffrés |
| `ansible/` | Playbooks, rôles, inventaire et procédures de bootstrap |
| `scripts/` | Validations, graphe de dépendances et audits |
| `.githooks/` | Contrôles pre-commit et pre-push |
| `.github/workflows/` | Validation GitHub Actions |

## Namespaces actifs observés

- `flux-system`
- `vault`
- `network`
- `cert-manager`
- `longhorn-system`
- `kube-system`
- `database`
- `observability`
- `default`
- `gpu`

## Familles de services

### Plateforme

Flux, Vault, Vault Secrets Operator, cert-manager, MetalLB, Traefik, CrowdSec, Headscale, Tailscale, Longhorn, local-path-provisioner, CSI SMB, Kubernetes Replicator, CNPG et kube-prometheus-stack.

### Données

CNPG, pgAdmin, pg-dump, pg-dump-sync, pg-loader et pg-restore. Les applications consomment PostgreSQL ou des services de cache selon les valeurs Helm et les secrets matérialisés.

### Applications

Le namespace `default` contient notamment Authentik, Immich, Jellyfin, Kavita, Mealie, OnlyOffice, Paperless, Prowlarr, Radarr, Sonarr, Autobrr, RabbitMQ et Valkey, ainsi que des applications de bibliothèque, productivité et test.

### Observabilité

Prometheus/Grafana via kube-prometheus-stack, Grafana, Kromgo et les règles d'alerte associées.

## Applications et utilités

Le tableau ci-dessous couvre les 51 frontières Flux actives détectées sous `kubernetes/apps/`. Une frontière Flux peut installer un opérateur, un chart, des ressources complémentaires ou une application complète.

Les utilités des composants de plateforme sont confirmées par leurs manifests et leurs dépendances. Pour certaines applications personnelles (`books`, `livres`, `christmas` et `automate-wx`), la description est une synthèse du nom, du namespace et de la configuration visible ; le comportement fonctionnel détaillé doit être confirmé dans l'application elle-même.

## Sources et stratégie des charts

Les sources sont déclarées dans `kubernetes/flux/meta/repositories/helm/` et consommées par les `HelmRelease` via `spec.chart.spec.sourceRef`. Le chart est donc une partie du contrat de déploiement, au même titre que les valeurs Helm et les ressources Kustomize locales.

| Stratégie | Source | Exemples observés |
| --- | --- | --- |
| Template commun pour applications simples | `bjw-s`, dépôt `https://bjw-s-labs.github.io/helm-charts`, chart `app-template` v5.1.0 | Autobrr, Books, Christmas, Endlessh, Filebrowser, Flaresolverr, Hajimari, Immich, Jellyfin, Kavita, Livres, Mealie, OnlyOffice, Paperless, Prowlarr, Radarr, Sonarr, Headscale, Headplane, Tailscale, Kromgo et plusieurs jobs/services simples |
| Chart applicatif dédié | Dépôt correspondant à l'éditeur ou au projet | Authentik, Coder, RabbitMQ, Valkey, pgAdmin, cert-manager, CNPG, Longhorn, MetalLB, Traefik, Grafana, kube-prometheus-stack, Vault, External Secrets et CSI SMB |
| OCI ou chart de plateforme spécifique | Source OCI ou dépôt Flux dédié | Flux Operator et Flux instance |

Principe de choix : une nouvelle application complexe qui dispose d'un chart maintenu par son projet doit utiliser ce chart applicatif dédié. Une application simple, sans chart applicatif nécessaire ou dont le déploiement se limite à un ou quelques workloads, doit utiliser `bjw-s-labs/app-template`. Toute exception doit être motivée dans la documentation ou dans le `ks.yaml` concerné. Les applications existantes qui ne suivent pas encore cette règle sont des candidates à revue, pas des migrations automatiques.

### Applications complexes à revoir

Le dépôt utilise actuellement `app-template` pour plusieurs applications à état ou à intégrations multiples, notamment Immich, Jellyfin, Paperless-ngx, Mealie et les services de bibliothèque. Il faut vérifier pour chacune si son projet fournit un chart officiel ou si l'usage d'`app-template` reste volontaire et mieux adapté aux besoins locaux.

## Posture de sécurité par namespace

Cette matrice porte sur les labels Pod Security Admission présents dans les manifests de namespace. Les `securityContext` Helm sont une seconde couche et ne permettent pas, seuls, de conclure sur la posture effective.

| Namespace | Indication dans le dépôt | Interprétation |
| --- | --- | --- |
| `gpu` | `pod-security.kubernetes.io/enforce=privileged` | Autorise explicitement le mode privilégié ; à limiter aux workloads GPU nécessaires. |
| `longhorn-system` | `pod-security.kubernetes.io/enforce=privileged` | Mode privilégié attendu pour le stockage et ses composants système. |
| `network` | `pod-security.kubernetes.io/enforce=privileged` | Mode privilégié déclaré pour les composants réseau ; à revoir composant par composant. |
| `observability` | `pod-security.kubernetes.io/enforce=privileged` | Mode privilégié déclaré ; vérifier s'il est nécessaire pour toute la namespace. |
| `cert-manager` | Aucun label namespace observé | Posture effective à vérifier sur le cluster et les pods générés. |
| `database` | Aucun label namespace observé | Posture effective à vérifier ; distinguer opérateur, bases et jobs de maintenance. |
| `vault` | Aucun label namespace observé | Posture effective à vérifier pour Vault et ses opérateurs. |
| `default`, `flux-system`, `kube-system` | Namespace non documenté par un manifest local dans cette analyse | Ne pas déduire la posture ; vérifier les labels et policies live. |

La prochaine revue de sécurité doit comparer les labels live avec les manifests, puis vérifier les exceptions `privileged`, `runAsNonRoot`, `allowPrivilegeEscalation`, capabilities et `seccompProfile` sur les workloads sensibles.

### Bootstrap et plateforme

| Namespace | Application | Utilité |
| --- | --- | --- |
| `flux-system` | `flux-operator` | Installe et configure les composants Flux qui réconcilient le dépôt Git. |
| `cert-manager` | `cert-manager` | Crée et renouvelle les certificats TLS via les issuers déclarés. |
| `kube-system` | `csi-driver-smb` | Permet de monter les partages SMB/NAS dans Kubernetes et fournit les StorageClasses NAS. |
| `kube-system` | `kubernetes-replicator` | Réplique certaines ressources Kubernetes partagées entre namespaces. |
| `longhorn-system` | `longhorn` | Fournit le stockage bloc distribué, les volumes persistants et les fonctions de backup/restore Longhorn. |
| `longhorn-system` | `local-path-provisioner` | Fournit un provisionnement local distinct de Longhorn. |
| `network` | `metallb` | Attribue des adresses IP LAN aux services Kubernetes de type LoadBalancer. |
| `network` | `traefik` | Reverse proxy et contrôleur d'ingress HTTP, TCP et UDP. |
| `network` | `crowdsec` | Détecte et bloque des comportements réseau malveillants, notamment via Traefik. |
| `network` | `ddns-updater` | Met à jour les enregistrements DNS dynamiques utilisés par les services exposés. |
| `network` | `headscale` | Fournit le control server Tailscale auto-hébergé pour le réseau privé. |
| `network` | `headplane` | Interface et gestion autour de Headscale. |
| `network` | `headscale-rotator` | Automatise la rotation ou la maintenance de ressources Headscale. |
| `network` | `tailscale` | Connecte le cluster au réseau privé Tailscale. |
| `network` | `upsnap` | Supervise ou pilote l'alimentation des équipements selon sa configuration. |
| `network` | `uptime-kuma` | Surveille la disponibilité des services et endpoints. |
| `observability` | `kube-prometeus-stack` | Déploie Prometheus, Alertmanager, exporters et règles de monitoring Kubernetes. |
| `observability` | `grafana` | Fournit les dashboards et la visualisation des métriques. |
| `observability` | `kromgo` | Expose des métriques synthétiques du cluster pour les badges et tableaux de statut. |
| `vault` | `vault` | Stocke et sert les secrets runtime ainsi que certaines identités/certificats. |
| `vault` | `vault-secrets-operator` | Matérialise des secrets Vault en Secrets Kubernetes via `VaultAuth` et `VaultStaticSecret`. |
| `vault` | `vault-external-secrets-operator` | Fournit l'opérateur External Secrets pour les intégrations de secrets externes déclarées. |

### Données et bases

| Namespace | Application | Utilité |
| --- | --- | --- |
| `database` | `cnpg` | Installe CloudNativePG et fournit l'opérateur PostgreSQL. |
| `database` | `pg-dump` | Produit des dumps PostgreSQL selon la configuration de l'application. |
| `database` | `pg-dump-sync` | Synchronise ou exporte les dumps PostgreSQL vers la cible configurée. |
| `database` | `pg-loader` | Charge des données ou des dumps PostgreSQL dans le circuit de données. |
| `database` | `pg-restore` | Restaure des bases PostgreSQL et leurs ressources associées. |
| `database` | `pgadmin` | Interface d'administration des bases PostgreSQL. |
| `default` | `rabbitmq` | Broker de messages utilisé par les applications qui déclarent ce besoin. |
| `default` | `valkey` | Service clé-valeur/cache utilisé notamment par Authentik et d'autres workloads. |

### Applications utilisateur et services métier

| Namespace | Application | Utilité |
| --- | --- | --- |
| `default` | `authentik` | Gestion d'identité, authentification et SSO pour les services protégés. |
| `default` | `autobrr` | Automatise des actions et notifications autour des téléchargements et médias. |
| `default` | `books` | Service ou bibliothèque de gestion de livres et fichiers associés. |
| `default` | `christmas` | Application de contenu ou d'usage saisonnier. |
| `default` | `test-christmas` | Variante de test de l'application saisonnière. |
| `default` | `coder` | Environnement de développement accessible depuis le cluster. |
| `default` | `endlessh` | Service leurre SSH qui ralentit les connexions automatisées indésirables. |
| `default` | `filebrowser` | Navigateur et gestionnaire de fichiers exposé sur les stockages configurés. |
| `default` | `flaresolverr` | Proxy de résolution de challenges utilisé par certains services média. |
| `default` | `hajimari` | Page d'accueil/dashbord pour accéder aux services du cluster. |
| `default` | `immich` | Gestion et indexation de photos et vidéos personnelles. |
| `default` | `jellyfin` | Serveur de streaming de contenus multimédias. |
| `default` | `kavita` | Lecteur et bibliothèque de livres, mangas et bandes dessinées. |
| `default` | `livres` | Service ou bibliothèque complémentaire dédiée aux livres. |
| `default` | `mealie` | Gestion de recettes, menus et planification de repas. |
| `default` | `onlyoffice` | Suite bureautique collaborative intégrée aux services concernés. |
| `default` | `paperless-ngx` | Gestion, classement et recherche de documents numériques. |
| `default` | `prowlarr` | Indexer manager partagé pour les applications de téléchargement. |
| `default` | `radarr` | Gestion automatisée des films et de leur téléchargement. |
| `default` | `sonarr` | Gestion automatisée des séries et de leur téléchargement. |

### GPU

| Namespace | Application | Utilité |
| --- | --- | --- |
| `gpu` | `automate-wx` | Workload applicatif nécessitant la capacité GPU déclarée dans le cluster. |

## Bootstrap Flux

Le fichier `kubernetes/flux/cluster/ks.yaml` définit deux ressources de niveau cluster :

| Ressource | Utilité |
| --- | --- |
| `cluster-meta` | Réconcilie `kubernetes/flux/meta/`, notamment les sources Helm, OCI et Git nécessaires aux charts. |
| `cluster-apps` | Dépend de `cluster-meta` puis réconcilie `kubernetes/apps/`. |

## Inventaire généré

Au moment du scan du 1 octobre 2026, le dépôt contient 51 fichiers `ks.yaml` et 51 fichiers `helmrelease.yaml` sous `kubernetes/`, en incluant les chemins actifs retournés par l'index du workspace. Les chemins sous `_archive/` doivent rester séparés de l'inventaire actif. Le bootstrap `kubernetes/flux/cluster/ks.yaml` orchestre `kubernetes/flux/meta/` puis `kubernetes/apps/`.

## Nœuds Talos déclarés

| Nœud | Rôle | Adresse | Fichier de référence |
| --- | --- | --- | --- |
| `nucoumouk` | control plane | `192.168.1.21` | `talos/talconfig.yaml` |
| `nucsamere` | worker | `192.168.1.20` | `talos/talconfig.yaml` |
| VIP cluster | endpoint Kubernetes | `192.168.1.5` | `talos/talconfig.yaml` |

Les nœuds commentés dans `talconfig.yaml` ne doivent pas être présentés comme actifs sans validation de l'état du cluster.
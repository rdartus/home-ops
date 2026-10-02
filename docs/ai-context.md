# Contexte structuré pour IA

## Identité

- `project`: `home-ops`
- `type`: dépôt GitOps et infrastructure as code
- `cluster`: `klusterfox`
- `as_of`: `2026-10-01`
- `architecture_mode`: brownfield, état existant décrit depuis le dépôt
- `desired_state_root`: `kubernetes/flux/cluster/ks.yaml` -> `kubernetes/flux/meta/` -> `kubernetes/apps/`
- `node_config_root`: `talos/`

## Vocabulaire

| Terme | Signification dans ce dépôt |
| --- | --- |
| `ks.yaml` | Manifeste Flux `Kustomization`, pas une Kustomization Kustomize ordinaire |
| `app/` | Répertoire de composition d'une application ou d'un contrôleur |
| `resources/` | Ressources dépendantes d'un composant déjà installé |
| `HelmRelease` | Contrat Flux pour installer ou mettre à jour un chart |
| `VaultAuth` | Authentification d'un workload auprès de Vault |
| `VaultStaticSecret` | Projection d'un secret Vault dans un Secret Kubernetes |
| `StorageClass` | Contrat de placement et de provisionnement des données |
| `dependsOn` | Ordre de réconciliation Flux et prérequis de readiness |
| `app-template` | Chart commun `bjw-s-labs` pour les applications simples et les workloads standardisés |
| chart dédié | Chart maintenu par le projet de l'application complexe |
| PSA | Pod Security Admission, contrôlé notamment par les labels de namespace |

## Règles de raisonnement

1. Chercher d'abord dans `kubernetes/apps/<namespace>/<application>/ks.yaml` pour comprendre le cycle Flux.
2. Lire ensuite `app/kustomization.yaml`, `helmrelease.yaml`, `helm-values.yaml` et les ressources de secrets/PVC/ingress.
3. Résoudre les dépendances via `spec.dependsOn`, pas via l'ordre alphabétique des dossiers.
4. Distinguer les ressources actives de `kubernetes/_archive/`.
5. Distinguer une valeur chiffrée SOPS d'un secret runtime fourni par Vault.
6. Traiter les fichiers générés ou ignorés comme des sorties dérivées, jamais comme des sources de vérité.
7. Marquer `[UNVERIFIED]` toute affirmation dépendant de l'état réel du cluster et absente des fichiers suivis.
8. Pour un nouveau déploiement, choisir un chart applicatif dédié si l'application complexe en fournit un ; sinon utiliser `bjw-s-labs/app-template` pour une application simple.
9. Ne jamais déduire la posture de sécurité d'un namespace à partir des seuls `securityContext` Helm ; vérifier aussi les labels PSA live.
10. Traiter Renovate comme le mécanisme normal de proposition des mises à jour et lire `.renovate/packageRules.json` avant de conclure qu'une mise à jour peut être auto-mergée.
11. Ne jamais auto-merger une mise à jour Talos ou Kubernetes ; suivre la procédure spécifique injectée dans la PR Renovate.
12. Préserver le graphe généré de `README.md` via le hook pre-commit et ne pas éditer manuellement son bloc Mermaid.

## Contrats d'architecture

- Git est la source de l'état désiré Kubernetes.
- Flux réconcilie ; Kustomize compose ; HelmRelease installe les charts.
- Les dépendances inter-composants doivent être exprimées par `dependsOn` et les contrôles de santé adaptés.
- Vault est la source runtime des secrets d'application ; SOPS protège les secrets stockés dans Git.
- Longhorn, SMB et local-path sont des capacités de stockage distinctes.
- MetalLB, Traefik et cert-manager forment le chemin normal d'exposition HTTP/TCP/UDP et TLS.
- Talos est configuré par `talconfig.yaml` et ses patches ; les configurations générées doivent être régénérées et validées.
- Les charts sont choisis selon la complexité : chart projet pour une application complexe, `bjw-s-labs/app-template` pour une application simple.
- Une namespace avec `pod-security.kubernetes.io/enforce=privileged` est une exception de sécurité à documenter, pas une posture globale acceptable par défaut.
- Renovate propose les mises à jour ; les hooks Git et la CI valident les manifests et le graphe Flux avant intégration.
- Les patchs applicatifs peuvent être auto-mergés selon les règles Renovate, mais les patchs Talos/Kubernetes exigent une fusion manuelle.

## Indices de confiance

- `VERIFIED_REPO`: chemins, relations et versions lus dans le dépôt.
- `VERIFIED_EXTERNAL`: rôle général confirmé par la documentation officielle du projet.
- `INFERRED`: relation déduite de plusieurs manifests, à conserver avec ses fichiers de preuve.
- `OPEN_QUESTION`: information opérationnelle non exprimée dans le dépôt.
- `STALE_OR_INCONSISTENT`: référence documentaire qui ne correspond pas à l'arborescence actuelle.

## Questions ouvertes

- L'endpoint Kromgo Flux répond actuellement `No Data`; ne pas présenter `2.7.x` du dépôt comme une version live vérifiée.
- Les objectifs RPO/RTO ne sont pas formalisés : il s'agit d'un homelab qui accepte de l'indisponibilité, avec une priorité déclarée de conservation des données lors d'un teardown.
- Les dépendances annotées `OPTIONAL` sont-elles nécessaires dans l'environnement actuel ?
- Quel est le producteur et le propriétaire de rotation de chaque secret partagé ou répliqué ?
- Quelle matrice classe chaque donnée entre restauration Longhorn, restauration PostgreSQL et sauvegarde NAS ?
- Quel profil ingress/TLS doit être obligatoire pour les nouveaux workloads ?
- Quelles applications actuellement sur `app-template` disposent-elles d'un chart officiel qui justifierait une migration ?
- Quels workloads ont réellement besoin des namespaces `privileged` et quelles namespaces peuvent passer à une politique restreinte ?
- Les procédures d'upgrade ajoutées aux PR Renovate restent-elles alignées avec l'état réel du cluster et le stockage Longhorn ?
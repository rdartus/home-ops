# Procédures d'exploitation

## Pré-requis locaux

Les scripts de validation nécessitent `bash`, `git`, `yq`, `kubectl`, `flux` et, selon l'audit, `ssh`, `psql`, `jq` et les utilitaires POSIX. Les versions exactes des binaires locaux ne sont pas centralisées dans le dépôt.

## Activer les hooks

```bash
git config core.hooksPath .githooks
```

Le hook pre-commit valide les références Kustomize staged, régénère le graphe Flux et stage `README.md`. Le hook pre-push lance le dry-run Flux.

## Hooks Git et intégrité documentaire

Le hook `pre-commit` est bloquant : il exige `scripts/validate-kustomization-paths.sh`, valide les Kustomizations staged, puis exécute `python3 scripts/flux-graph.py --update-readme` et ajoute `README.md` au commit. Le graphe Mermaid de `README.md` ne doit donc pas être modifié manuellement.

Le hook `pre-push` est bloquant : il exige `scripts/flux-preflight.sh` et lance le build Flux dry-run sur les Kustomizations actives. Les deux hooks utilisent `set -euo pipefail` ; une dépendance manquante ou une validation en échec arrête l'opération.

## Valider les manifests

```bash
bash scripts/validate-kustomization-paths.sh --all
bash scripts/flux-preflight.sh
```

Le premier script vérifie les références locales puis exécute `kubectl kustomize`. Le second construit chaque Flux Kustomization active avec `flux build kustomization --dry-run` et ignore `_archive/` par défaut.

Pour inclure l'archive :

```bash
bash scripts/flux-preflight.sh --include-archive
```

## Mettre à jour le graphe

```bash
python3 scripts/flux-graph.py --update-readme
```

Le script lit les `ks.yaml`, extrait les `dependsOn` et remplace le bloc Mermaid de la section `Cluster layout` dans `README.md`.

## Modifier Talos

Après modification de `talos/talconfig.yaml` ou d'un patch :

```bash
cd talos
talhelper genconfig
talosctl validate --config clusterconfig/klusterfox-nucoumouk.yaml --mode metal
talosctl validate --config clusterconfig/klusterfox-nucsamere.yaml --mode metal
```

Comparer ensuite la configuration générée avec la configuration déployée avant application. Pour un changement day-2, la procédure documentée utilise `talhelper gencommand apply | bash`. Pour une reconstruction complète, vérifier l'endpoint control plane avant toute commande de reset, confirmer explicitement qu'un wipe est voulu, puis appliquer la génération et le bootstrap dans l'ordre décrit dans `ansible/README.md`.

Ne pas lancer `talhelper gensecret` sur le cluster existant ; cette opération est réservée à une reconstruction complète volontaire.

## Gérer les secrets

- Ne jamais produire ou committer de secret déchiffré.
- Vérifier `.sops.yaml` avant d'ajouter un fichier sensible.
- Pour les secrets runtime, suivre le circuit Vault `VaultAuth`/`VaultStaticSecret` existant dans le namespace concerné.
- Ne pas contourner Flux par une modification impérative durable ; une opération manuelle doit être suivie de la correction de l'état Git si elle doit persister.

## Bases et restauration

Les ressources CNPG, pg-dump, pg-dump-sync, pg-loader et pg-restore sont regroupées sous `kubernetes/apps/database/`. `scripts/immich-audit.sh` peut comparer les fichiers NAS avec la base Immich et utilise soit l'IP MetalLB PostgreSQL, soit un fallback `kubectl exec` vers le pod primaire.

Ce homelab ne définit pas de RPO/RTO formels et accepte de l'indisponibilité. La priorité déclarée est de préserver les données lors d'un teardown complet ; la cible de sauvegarde, la rétention et la validation périodique des restaurations restent des détails à préciser lorsqu'une procédure concrète l'exige. Toute procédure de restauration doit documenter la classe de données, la source choisie entre Longhorn et PostgreSQL, l'impact sur les applications et la vérification post-restore.

## CI

`.github/workflows/gitops-validate.yaml` installe `jq`, `yq`, `kubectl` et Flux, puis exécute la validation Kustomize et le preflight Flux pour les changements sous `kubernetes/`, `scripts/`, `.githooks/` ou le workflow lui-même.

## Renovate et mises à jour

Renovate est configuré par `renovate.json` et `.renovate/packageRules.json`.

- Managers actifs : `flux`, `kubernetes`, `helm-values`, `dockerfile` et `custom.regex`.
- Les fichiers Kubernetes suivis sont sous `kubernetes/**/*.yaml` ou `kubernetes/**/*.yml`.
- `_archive/` et `.vscode/` sont ignorés.
- Les mises à jour majeures et mineures restent visibles dans le flux normal Renovate.
- Les patchs applicatifs sont auto-mergés comme PR ; Flux applique ensuite le changement après merge.
- Les patchs Talos et Kubernetes restent sans auto-merge et doivent être fusionnés manuellement.
- Les mises à jour majeures de `kube-prometheus-stack` restent autorisées, tandis que ses mises à jour mineures, patch, pin et digest sont désactivées.
- La règle historique `mysql` sous `kubotheque` limite la version à `>=8.0 <8.1`.
- Les limites Renovate sont désactivées par heure, avec au plus 25 PR et 25 branches concurrentes ; la création des PR est immédiate.

Les managers regex suivent aussi les versions Talos dans `talos/talconfig.yaml` et `talos/patches/*.yaml`, ainsi que la version Kubernetes dans `talos/talconfig.yaml`.

### Upgrade Talos via PR Renovate

Une PR Talos doit suivre la procédure injectée par les règles Renovate : régénérer et valider les configurations, utiliser `talhelper gencommand upgrade --extra-flags "--preserve"`, vérifier l'endpoint control plane, puis contrôler les versions des nœuds et l'état des pods. L'option `--preserve` est obligatoire pour tenir compte du stockage Longhorn avec réplica unique sur la même partition que l'OS.

### Upgrade Kubernetes via PR Renovate

Une PR Kubernetes doit régénérer la configuration avec `talhelper genconfig`, produire puis vérifier `talhelper gencommand upgrade-k8s`, et contrôler ensuite `kubectl version` ainsi que les pods `kube-system`.
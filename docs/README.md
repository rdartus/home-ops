# Documentation de home-ops

Cette documentation décrit le dépôt GitOps, le cluster Kubernetes et les outils d'exploitation à partir de l'état du dépôt vérifié le 1 octobre 2026.

## Parcours recommandé

1. [Architecture technique](architecture.md)
2. [Inventaire du dépôt et du cluster](inventory.md)
3. [Procédures d'exploitation](operations.md)
4. [Contexte structuré pour IA](ai-context.md)
5. [Spine d'architecture](../_bmad-output/planning-artifacts/architecture/architecture-home-ops-2026-10-01/ARCHITECTURE-SPINE.md)

## Sources de vérité

- L'état désiré Kubernetes et Flux est dans `kubernetes/`.
- La définition Talos du cluster est dans `talos/talconfig.yaml`, `talos/talenv.yaml` et `talos/patches/`.
- Le provisioning historique et les procédures WSL/Ansible sont dans `ansible/README.md` et `ansible/`.
- Les contrôles automatisés sont dans `scripts/`, `.githooks/` et `.github/workflows/gitops-validate.yaml`.
- Les versions déclarées du cluster sont dans `talos/talconfig.yaml` et `talos/talenv.yaml`.
- Les secrets doivent rester chiffrés selon `.sops.yaml`.

## Statut documentaire

Les descriptions de structure et de flux sont fondées sur le dépôt. Les objectifs de sauvegarde, de restauration, de rétention et de disponibilité ne sont pas entièrement exprimés dans les manifests et restent à confirmer par le mainteneur. Le README et `flux-graph.md` contiennent aussi des références à `cluster-meta` et `cluster-apps` qui ne correspondent pas à des chemins présents dans l'arborescence actuelle.
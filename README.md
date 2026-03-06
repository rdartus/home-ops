<div align="center">



### My _geeked_ homelab k8s cluster <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="16" height="16">

_... automated via [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate)  <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16">

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/home-operations)&nbsp;&nbsp;
[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue&label=%20)](https://talos.dev)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=%20)](https://kubernetes.io)&nbsp;&nbsp;
[![Flux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fflux_version&style=for-the-badge&logo=flux&logoColor=white&color=blue&label=%20)](https://fluxcd.io)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/rdartus/home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/rdartus/home-ops/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Alertmanager](https://img.shields.io/endpoint?url=https%3A%2F%2Fhealthchecks.io%2Fb%2F2%2Fd6a71d48-9e97-4ba0-b7a0-ed0677d78304.shields&style=for-the-badge&logo=prometheus&logoColor=white&label=Alertmanager)](https://status.k13.dev)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Power-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fcluster_power_usage&style=flat-square&label=Power)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Alerts](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.dartus.fr%2Fcluster_alert_count&style=flat-square&label=Alerts)](https://github.com/kashalls/kromgo)

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a1/512.gif" alt="💡" width="20" height="20"> Overview

This is a repository for my home infrastructure and Kubernetes cluster. I try to adhere to Infrastructure as Code (IaC) and GitOps practices using tools like [Kubernetes](https://github.com/kubernetes/kubernetes), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate), and [GitHub Actions](https://github.com/features/actions).

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1faa9/512.gif" alt="🪩" width="20" height="20"> Kubernetes

This hobo cluster operates on [Talos Linux](https://github.com/siderolabs/talos), an immutable and ephemeral Linux distribution tailored for [Kubernetes](https://github.com/kubernetes/kubernetes), and is deployed on bare-metal [RPI](https://store.minisforum.com/products/minisforum-ms-a2) & [NUC](https://store.minisforum.com/products/minisforum-ms-a2) workstations. [Longhorn](https://github.com/rook/rook) supplies my workloads with persistent block, object, and file storage, while a separate server handles media file storage. The cluster is designed to enable a full teardown without any data loss but some downtime.

There is a template at [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) if you want to follow along with some of the practices I use here.

### Core Components

- [cert-manager](https://github.com/cert-manager/cert-manager): Creates SSL certificates for services in my cluster.
- [longhron](https://longhorn.io/): Distributed block storage for peristent storage.
- [flannel](https://flannel) : internal networking for my workloads.
- [vault](https://vault): Creates SSL certificates for services in my cluster.
- [wireguard](https://wireguard): VPN for remote access & local ip address while roaming.
- [Postgres](https://wireguard): CNPG Operator for eazy PG Management.
- [MetalLB](https://wireguard): LB to expose only 1 IP to router.
- [Authentik](https://wireguard): IDM, SSO for securing the apps.
- [Hajimari](https://wireguard): Sleek but unmaintained home page.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [kubernetes](./kubernetes) folder (see Directories below) and makes the changes to my clusters based on the state of my Git repository.

The way Flux works for me here is it will recursively search the [kubernetes/apps](./kubernetes/apps) folder until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations (`ks.yaml`). Under the control of those Flux kustomizations there will be a `HelmRelease` or other resources related to the application which will be applied.

[Renovate](https://github.com/renovatebot/renovate) monitors my **entire** repository for dependency updates, automatically creating a PR when updates are found. When some PRs are merged Flux applies the changes to my cluster.

### Directories

This Git repository contains the following directories under [kubernetes](./kubernetes).

```sh
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 apps          # Apps deployed into my cluster grouped by namespace (see below)
├─📁 components    # Re-usable kustomize components
└─📁 flux          # Flux system configuration
```

### Cluster layout

This is a high-level look how Flux deploys my applications with dependencies. Below there are 3 Flux kustomizations `postgres`, `postgres-cluster`, and `atuin`. `postgres` is the first app that needs to be running and healthy before `postgres-cluster` and once `postgres-cluster` is healthy `atuin` will be deployed.

```mermaid
graph TD;
  cert_manager__cert_manager["Kustomization: cert-manager"]
  cert_manager__cert_manager_issuers["Kustomization: cert-manager-issuers"]
  database__cnpg["Kustomization: cnpg"]
  database__cnpg_resources["Kustomization: cnpg-resources"]
  database__pg_dump["Kustomization: pg-dump"]
  database__pg_dump_sync["Kustomization: pg-dump-sync"]
  database__pg_restore["Kustomization: pg-restore"]
  database__pgadmin["Kustomization: pgadmin"]
  default__authentik["Kustomization: authentik"]
  default__autobrr["Kustomization: autobrr"]
  default__automate_wx["Kustomization: automate-wx"]
  default__books["Kustomization: books"]
  default__christmas["Kustomization: christmas"]
  default__coder["Kustomization: coder"]
  default__endlessh["Kustomization: endlessh"]
  default__filebrowser["Kustomization: filebrowser"]
  default__flaresolverr["Kustomization: flaresolverr"]
  default__ghostfolio["Kustomization: ghostfolio"]
  default__hajimari["Kustomization: hajimari"]
  default__immich["Kustomization: immich"]
  default__jellyfin["Kustomization: jellyfin"]
  default__kavita["Kustomization: kavita"]
  default__kubotheque["Kustomization: kubotheque"]
  default__livres["Kustomization: livres"]
  default__mealie["Kustomization: mealie"]
  default__onlyoffice["Kustomization: onlyoffice"]
  default__paperless["Kustomization: paperless"]
  default__prowlarr["Kustomization: prowlarr"]
  default__qbittorrent["Kustomization: qbittorrent"]
  default__rabbitmq["Kustomization: rabbitmq"]
  default__rabbitmq_resources["Kustomization: rabbitmq-resources"]
  default__radarr["Kustomization: radarr"]
  default__redis["Kustomization: redis"]
  default__sonarr["Kustomization: sonarr"]
  default__tandoor["Kustomization: tandoor"]
  default__test_christmas["Kustomization: test-christmas"]
  default__valkey["Kustomization: valkey"]
  default__ygege["Kustomization: ygege"]
  default__zitadel["Kustomization: zitadel"]
  flux_system__cluster_apps["Kustomization: cluster-apps"]
  flux_system__cluster_meta["Kustomization: cluster-meta"]
  flux_system__flux_instance["Kustomization: flux-instance"]
  flux_system__flux_operator["Kustomization: flux-operator"]
  kube_system__csi_driver_smb["Kustomization: csi-driver-smb"]
  kube_system__csi_driver_smb_ressources["Kustomization: csi-driver-smb-ressources"]
  kube_system__kubernetes_replicator["Kustomization: kubernetes-replicator"]
  longhorn_system__local_path_provisioner["Kustomization: local-path-provisioner"]
  longhorn_system__longhorn["Kustomization: longhorn"]
  longhorn_system__longhorn_resources["Kustomization: longhorn-resources"]
  longhorn_system__longhorn_restore["Kustomization: longhorn-restore"]
  network__crowdsec["Kustomization: crowdsec"]
  network__ddns_updater["Kustomization: ddns-updater"]
  network__metallb["Kustomization: metallb"]
  network__metallb_resources["Kustomization: metallb-resources"]
  network__traefik["Kustomization: traefik"]
  network__traefik_resources["Kustomization: traefik-resources"]
  network__wireguard["Kustomization: wireguard"]
  observability__grafana["Kustomization: grafana"]
  observability__kromgo["Kustomization: kromgo"]
  observability__kube_prometeus_stack["Kustomization: kube-prometeus-stack"]
  vault__vault["Kustomization: vault"]
  vault__vault_secrets_operator["Kustomization: vault-secrets-operator"]

  cert_manager__cert_manager -->|"Depends on"| network__traefik
  cert_manager__cert_manager -->|"Depends on"| observability__grafana
  cert_manager__cert_manager -->|"Depends on"| observability__kromgo
  cert_manager__cert_manager -->|"Depends on"| vault__vault_secrets_operator
  cert_manager__cert_manager_issuers -->|"Depends on"| cert_manager__cert_manager
  cert_manager__cert_manager_issuers -->|"Depends on"| network__traefik
  cert_manager__cert_manager_issuers -->|"Depends on"| vault__vault_secrets_operator
  database__cnpg -->|"Depends on"| cert_manager__cert_manager_issuers
  database__cnpg -->|"Depends on"| longhorn_system__longhorn
  database__cnpg_resources -->|"Depends on"| cert_manager__cert_manager_issuers
  database__cnpg_resources -->|"Depends on"| database__cnpg
  database__cnpg_resources -->|"Depends on"| kube_system__kubernetes_replicator
  database__pg_dump -->|"Depends on"| database__cnpg
  database__pg_dump -->|"Depends on"| longhorn_system__longhorn_restore
  database__pg_dump -->|"Depends on"| network__traefik
  database__pg_dump -->|"Depends on"| vault__vault_secrets_operator
  database__pg_dump_sync -->|"Depends on"| database__cnpg
  database__pg_dump_sync -->|"Depends on"| longhorn_system__longhorn_restore
  database__pg_dump_sync -->|"Depends on"| network__traefik
  database__pg_dump_sync -->|"Depends on"| vault__vault_secrets_operator
  database__pg_restore -->|"Depends on"| database__cnpg
  database__pg_restore -->|"Depends on"| database__cnpg_resources
  database__pg_restore -->|"Depends on"| kube_system__kubernetes_replicator
  database__pg_restore -->|"Depends on"| network__traefik
  database__pg_restore -->|"Depends on"| vault__vault_secrets_operator
  database__pgadmin -->|"Depends on"| database__cnpg_resources
  database__pgadmin -->|"Depends on"| default__authentik
  database__pgadmin -->|"Depends on"| network__traefik
  database__pgadmin -->|"Depends on"| vault__vault_secrets_operator
  default__authentik -->|"Depends on"| default__valkey
  default__authentik -->|"Depends on"| network__traefik
  default__authentik -->|"Depends on"| vault__vault_secrets_operator
  default__autobrr -->|"Depends on"| default__authentik
  default__autobrr -->|"Depends on"| default__sonarr
  default__autobrr -->|"Depends on"| network__traefik
  default__autobrr -->|"Depends on"| vault__vault_secrets_operator
  default__automate_wx -->|"Depends on"| vault__vault_secrets_operator
  default__books -->|"Depends on"| default__jellyfin
  default__books -->|"Depends on"| default__radarr
  default__books -->|"Depends on"| longhorn_system__longhorn_restore
  default__books -->|"Depends on"| network__traefik
  default__books -->|"Depends on"| vault__vault_secrets_operator
  default__coder -->|"Depends on"| default__authentik
  default__coder -->|"Depends on"| default__radarr
  default__coder -->|"Depends on"| longhorn_system__longhorn_restore
  default__coder -->|"Depends on"| network__traefik
  default__coder -->|"Depends on"| vault__vault_secrets_operator
  default__endlessh -->|"Depends on"| default__books
  default__endlessh -->|"Depends on"| network__traefik
  default__filebrowser -->|"Depends on"| default__authentik
  default__filebrowser -->|"Depends on"| kube_system__csi_driver_smb_ressources
  default__filebrowser -->|"Depends on"| vault__vault_secrets_operator
  default__flaresolverr -->|"Depends on"| default__filebrowser
  default__flaresolverr -->|"Depends on"| default__immich
  default__ghostfolio -->|"Depends on"| default__valkey
  default__hajimari -->|"Depends on"| default__automate_wx
  default__hajimari -->|"Depends on"| network__traefik
  default__immich -->|"Depends on"| database__cnpg_resources
  default__immich -->|"Depends on"| default__authentik
  default__immich -->|"Depends on"| default__filebrowser
  default__immich -->|"Depends on"| default__valkey
  default__immich -->|"Depends on"| longhorn_system__longhorn_restore
  default__immich -->|"Depends on"| vault__vault_secrets_operator
  default__jellyfin -->|"Depends on"| default__filebrowser
  default__jellyfin -->|"Depends on"| default__immich
  default__jellyfin -->|"Depends on"| default__prowlarr
  default__jellyfin -->|"Depends on"| network__traefik
  default__jellyfin -->|"Depends on"| vault__vault_secrets_operator
  default__kavita -->|"Depends on"| database__cnpg
  default__kavita -->|"Depends on"| default__filebrowser
  default__kavita -->|"Depends on"| default__immich
  default__kavita -->|"Depends on"| longhorn_system__longhorn_restore
  default__kavita -->|"Depends on"| network__traefik
  default__kavita -->|"Depends on"| vault__vault_secrets_operator
  default__livres -->|"Depends on"| default__jellyfin
  default__livres -->|"Depends on"| default__radarr
  default__livres -->|"Depends on"| longhorn_system__longhorn_restore
  default__livres -->|"Depends on"| network__traefik
  default__livres -->|"Depends on"| vault__vault_secrets_operator
  default__mealie -->|"Depends on"| database__cnpg
  default__mealie -->|"Depends on"| default__filebrowser
  default__mealie -->|"Depends on"| default__immich
  default__mealie -->|"Depends on"| longhorn_system__longhorn_restore
  default__mealie -->|"Depends on"| network__traefik
  default__mealie -->|"Depends on"| vault__vault_secrets_operator
  default__onlyoffice -->|"Depends on"| database__cnpg_resources
  default__onlyoffice -->|"Depends on"| vault__vault_secrets_operator
  default__paperless -->|"Depends on"| default__valkey
  default__prowlarr -->|"Depends on"| default__authentik
  default__prowlarr -->|"Depends on"| default__sonarr
  default__prowlarr -->|"Depends on"| network__traefik
  default__prowlarr -->|"Depends on"| vault__vault_secrets_operator
  default__qbittorrent -->|"Depends on"| default__prowlarr
  default__qbittorrent -->|"Depends on"| longhorn_system__longhorn_resources
  default__qbittorrent -->|"Depends on"| network__traefik
  default__qbittorrent -->|"Depends on"| vault__vault_secrets_operator
  default__rabbitmq -->|"Depends on"| vault__vault_secrets_operator
  default__rabbitmq_resources -->|"Depends on"| default__rabbitmq
  default__radarr -->|"Depends on"| default__authentik
  default__radarr -->|"Depends on"| default__sonarr
  default__radarr -->|"Depends on"| network__traefik
  default__radarr -->|"Depends on"| vault__vault_secrets_operator
  default__redis -->|"Depends on"| vault__vault_secrets_operator
  default__sonarr -->|"Depends on"| database__cnpg
  default__sonarr -->|"Depends on"| default__authentik
  default__sonarr -->|"Depends on"| default__flaresolverr
  default__sonarr -->|"Depends on"| network__traefik
  default__sonarr -->|"Depends on"| vault__vault_secrets_operator
  default__tandoor -->|"Depends on"| database__cnpg
  default__tandoor -->|"Depends on"| default__filebrowser
  default__tandoor -->|"Depends on"| default__immich
  default__tandoor -->|"Depends on"| longhorn_system__longhorn_restore
  default__tandoor -->|"Depends on"| network__traefik
  default__tandoor -->|"Depends on"| vault__vault_secrets_operator
  default__ygege -->|"Depends on"| default__authentik
  default__ygege -->|"Depends on"| default__sonarr
  default__ygege -->|"Depends on"| network__traefik
  default__ygege -->|"Depends on"| vault__vault_secrets_operator
  default__zitadel -->|"Depends on"| default__authentik
  default__zitadel -->|"Depends on"| network__traefik
  default__zitadel -->|"Depends on"| vault__vault_secrets_operator
  flux_system__cluster_apps -->|"Depends on"| flux_system__cluster_meta
  kube_system__csi_driver_smb -->|"Depends on"| network__traefik
  kube_system__csi_driver_smb -->|"Depends on"| vault__vault_secrets_operator
  kube_system__csi_driver_smb_ressources -->|"Depends on"| network__traefik
  kube_system__csi_driver_smb_ressources -->|"Depends on"| vault__vault_secrets_operator
  longhorn_system__longhorn -->|"Depends on"| network__metallb
  longhorn_system__longhorn -->|"Depends on"| network__traefik_resources
  longhorn_system__longhorn -->|"Depends on"| vault__vault_secrets_operator
  longhorn_system__longhorn_resources -->|"Depends on"| longhorn_system__longhorn
  longhorn_system__longhorn_restore -->|"Depends on"| longhorn_system__longhorn_resources
  network__crowdsec -->|"Depends on"| vault__vault_secrets_operator
  network__ddns_updater -->|"Depends on"| network__traefik
  network__ddns_updater -->|"Depends on"| vault__vault_secrets_operator
  network__metallb_resources -->|"Depends on"| network__metallb
  network__traefik_resources -->|"Depends on"| network__crowdsec
  network__traefik_resources -->|"Depends on"| network__metallb
  network__traefik_resources -->|"Depends on"| network__traefik
  network__wireguard -->|"Depends on"| vault__vault_secrets_operator
  observability__grafana -->|"Depends on"| network__metallb_resources
  observability__grafana -->|"Depends on"| network__traefik
  observability__grafana -->|"Depends on"| observability__kube_prometeus_stack
  observability__grafana -->|"Depends on"| vault__vault_secrets_operator
  observability__kromgo -->|"Depends on"| network__metallb_resources
  observability__kromgo -->|"Depends on"| network__traefik
  observability__kromgo -->|"Depends on"| observability__kube_prometeus_stack
  observability__kromgo -->|"Depends on"| vault__vault_secrets_operator
  observability__kube_prometeus_stack -->|"Depends on"| longhorn_system__longhorn_resources
  observability__kube_prometeus_stack -->|"Depends on"| network__traefik_resources
  observability__kube_prometeus_stack -->|"Depends on"| vault__vault_secrets_operator
  vault__vault_secrets_operator -->|"Depends on"| vault__vault
```

### Networking

<details>
  <summary>Click to see a high-level network diagram</summary>

  <img src="https://github.com/user-attachments/assets/c6bb2848-d900-4796-975b-4e80dcba4850" align="center" width="600px" alt="network"/>
</details>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f30e/512.gif" alt="🌎" width="20" height="20"> DNS

In my cluster there are two instances of [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) running. One for syncing private DNS records to my `UDM Pro Max` using [ExternalDNS webhook provider for UniFi](https://github.com/kashalls/external-dns-unifi-webhook), while another instance syncs public DNS to `Cloudflare`. This setup is managed by creating routes with two specific gatways: `internal` for private DNS and `external` for public DNS. The `external-dns` instances then syncs the DNS records to their respective platforms accordingly.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2699_fe0f/512.gif" alt="⚙" width="20" height="20"> Hardware


| Device                        | Count | OS Disk Size   | Data Disk Size             | Ram   | Operating System | Purpose                 |
|-------------------------------|-------|---------------|-----------------------------|-------|------------------|-------------------------|
| Intel NUC                     | 1     | 160GB M.2     | -                           | 16GB  | Talos            | Kubernetes              |
| Raspberry Pi 5                | 1     | 64GB (SD)     | -                           | 8GB   | Talos            | Kubernetes              |
| Raspberry Pi 4                | 1     | 64GB (SD)     | -                           | 8GB   | PiKVM            | NAS                     |
| Raspberry Pi ZeroW            | 1     | 16GB (SD)     | -                           | 0,5GB | Raspberry Pi OS  | DNS Server              |

---


## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f31f/512.gif" alt="🌟" width="20" height="20"> Stargazers

<div align="center">

<a href="https://star-history.com/#rdartus/home-ops&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=rdartus/home-ops&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=rdartus/home-ops&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=rdartus/home-ops&type=Date" />
  </picture>
</a>

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f64f/512.gif" alt="🙏" width="20" height="20"> Gratitude and Thanks

Many thanks to all the fantastic people who donate their time to the [Home Operations](https://discord.gg/home-operations) Discord community. Be sure to check out [kubesearch.dev](https://kubesearch.dev) for ideas on how to deploy applications or get ideas on what you may deploy.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6a7/512.gif" alt="🚧" width="20" height="20"> Changelog

See the latest [release](https://github.com/rdartus/home-ops/releases/latest) notes.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2696_fe0f/512.gif" alt="⚖" width="20" height="20"> License

See [LICENSE](./LICENSE).

---
## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f308/512.gif" alt="🌈" width="20" height="20"> Usefull notes & cmd
WSL Conf
``` zsh
cd ~/code/jeanpi/ && sudo docker compose down && cp ~/config/radarr/radarr.db ~/tmp/radarr.db && cp ~/config/sonarr/sonarr.db ~/tmp/sonarr.db && cp ~/config/prowlarr/prowlarr.db ~/tmp/prowlarr.db && cd ~/code/jeanpi/ && sudo docker compose up -d

scp -P 22022 jeank@192.168.1.32:/home/jeank/.kube/config /home/jeank/.kube/config
scp -P 22022 jeank@192.168.1.16:/home/jeank/tmp/prowlarr.db /home/jeank/k3s-argo/db/prowlarr.db
scp -P 22022 jeank@192.168.1.16:/home/jeank/tmp/radarr.db /home/jeank/k3s-argo/db/radarr.db
scp -P 22022 jeank@192.168.1.16:/home/jeank/tmp/sonarr.db /home/jeank/k3s-argo/db/sonarr.db
scp /home/jeank/k3s-argo/db/prowlarr.db jeank@192.168.1.32:/home/jeank/k3s-argo/db/prowlarr.db
scp /home/jeank/k3s-argo/db/radarr.db jeank@192.168.1.32:/home/jeank/k3s-argo/db/radarr.db
scp /home/jeank/k3s-argo/db/sonarr.db jeank@192.168.1.32:/home/jeank/k3s-argo/db/sonarr.db
sed -i 's/127.0.0.1/192.168.1.32/g' ~/.kube/config
```

Deploy JeanKluter & K3S : 
``` zsh
kubectl apply -k ~/k3s-argo/localApps/kusto-argo/
kubectl apply -k ~/k3s-argo/localApps
sudo k3s ctl images import k3s-argo/pgloader.tar
```
Vault Conf :
```zsh
mkdir ~/cred
sudo chown jeank:1000 cred
kubectl exec -it vault-0 -- /bin/sh vault auth enable kubernetes
kubectl exec -it vault-0 -- /bin/sh vault operator init -key-shares=3 -key-threshold=2
kubectl exec -it vault-0 -- /bin/sh vault operator
kubectl exec -it $(kubectl get pod -l app.kubernetes.io/name=traefik -n traefik -o jsonpath='{.items[0].metadata.name}') -n traefik -- /bin/sh

```

Get logs
```zsh
kubectl logs svc/argocd-server -n argocd  > argo.log && kubectl logs svc/argocd-repo-server -n argocd  > argorepo.log && kubectl logs svc/webhook-service -n metallb > metallb.log && kubectl logs pod/speaker-stlm6 -n metallb > speaker.log
```

Delete :
```zsh
kubectl delete pod -l app.kubernetes.io/component=speaker -n metallb
```

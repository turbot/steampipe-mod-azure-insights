## v0.14 [2024-01-09]

_Bug fixes_

- Fixed the `network_subnet_to_network_virtual_network` edge of the relationship graph in the `sql_server_detail` dashboard page to correctly reference the `network_subnets_for_sql_server` query. ([#118](https://github.com/turbot/steampipe-mod-azure-insights/pull/118))

## v0.13 [2023-11-03]

_Breaking changes_

- Updated the plugin dependency section of the mod to use `min_version` instead of `version`. ([#115](https://github.com/turbot/steampipe-mod-azure-insights/pull/115))

## v0.12 [2023-08-07]

_Bug fixes_

- Updated the Age Report dashboards to order by the creation time of the resource. ([#106](https://github.com/turbot/steampipe-mod-azure-insights/pull/106))

## v0.11 [2023-07-13]

_What's new?_

- New dashboards added: ([#105](https://github.com/turbot/steampipe-mod-azure-insights/pull/105)) (Thanks [@jonesy1234](https://github.com/jonesy1234) for the contribution!)
  - [Azure Network Express Route Circuit Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.network_express_route_circuit_dashboard)
  - [Azure Network Express Route Circuit Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.network_express_route_circuit_detail)

## v0.10 [2023-05-31]

_Bug fixes_

- Fixed `Azure SQL Database Detail`, `Azure SQL Database Dashboard`, `Azure SQL Database Age Report`, and `Azure SQL Server Detail` dashboards to include the Azure SQL master database information. ([#102](https://github.com/turbot/steampipe-mod-azure-insights/pull/102))
- Fixed dashboard localhost URLs in README and index doc. ([#100](https://github.com/turbot/steampipe-mod-azure-insights/pull/100))

## v0.9 [2023-04-05]

_Bug fixes_

- Added missing `args` to public access card in `Azure Kubernetes Cluster Detail` dashboard.

## v0.8 [2023-04-05]

_Dependencies_

- Azure plugin `v0.40.1` or higher is now required. ([#94](https://github.com/turbot/steampipe-mod-azure-insights/pull/94))

_What's new?_

- New dashboards added: ([#93](https://github.com/turbot/steampipe-mod-azure-insights/pull/93))
  - [Azure CosmosDB Account Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.cosmosdb_account_dashboard)
  - [Azure CosmosDB Account Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.cosmosdb_account_detail)
  - [Azure CosmosDB Account Encryption Report](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.cosmosdb_account_encryption_report)
  - [Azure CosmosDB Mongo Database Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.cosmosdb_mongo_database_detail)
  - [Azure Kubernetes Cluster Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.kubernetes_cluster_dashboard)

## v0.7 [2023-03-15]

_Bug fixes_

- Fixed `Azure Compute Virtual Machine Dashboard`, `Azure Compute Virtual Machine Detail`, `Azure Network Security Group Dashboard`, `Azure Network Security Group Detail` and `Azure Virtual Network Detail` dashboards to correctly reflect the configured network security group rules. ([#88](https://github.com/turbot/steampipe-mod-azure-insights/pull/88))

## v0.6 [2023-02-03]

_Enhancements_

- Updated the `card` width across all the dashboards to enhance readability. ([#83](https://github.com/turbot/steampipe-mod-azure-insights/pull/83))

## v0.5 [2023-01-12]

_Dependencies_

- Steampipe `v0.18.0` or higher is now required. ([#80](https://github.com/turbot/steampipe-mod-azure-insights/pull/80))
- Azure plugin `v0.35.1` or higher is now required. ([#80](https://github.com/turbot/steampipe-mod-azure-insights/pull/80))
- Azure Active Directory plugin `v0.8.3` or higher is now required. ([#80](https://github.com/turbot/steampipe-mod-azure-insights/pull/80))

_What's new?_

- Added resource relationship graphs across all the detail dashboards to highlight the relationship the resource shares with other resources. ([#79](https://github.com/turbot/steampipe-mod-azure-insights/pull/79))
- New dashboards added: ([#79](https://github.com/turbot/steampipe-mod-azure-insights/pull/79))
  - [Azure App Service Web App Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.app_service_web_app_dashboard)
  - [Azure App Service Web App Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.app_service_web_app_detail)
  - [Azure Compute Disk Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.compute_disk_detail)
  - [Azure Compute Snapshot Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.compute_snapshot_detail)
  - [Azure Compute Virtual Machine Scale Set VM Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.compute_virtual_machine_scale_set_vm_detail)
  - [Azure Key Vault Key Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.key_vault_key_detail)
  - [Azure Kubernetes Cluster Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.kubernetes_cluster_detail)
  - [Azure Network Firewall Detail"](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.network_firewall_detail)
  - [Azure Network Interface Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.network_interface_detail)
  - [Azure Network Load Balancer Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.network_load_balancer_detail)
  - [Azure Network Public IP Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.network_public_ip_detail)
  - [Azure Network Subnet Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.network_subnet_detail)

## v0.4 [2022-05-09]

_Enhancements_

- Updated docs/index.md and README to the latest format. ([#17](https://github.com/turbot/steampipe-mod-azure-tags/pull/17))

## v0.3 [2022-04-22]

_What's new?_

- New dashboards added:
  - [Active Directory Group Detail Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azuread_group_detail) ([#27](https://github.com/turbot/steampipe-mod-azure-insights/pull/27))
  - [Active Directory User Detail Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azuread_user_detail) ([#27](https://github.com/turbot/steampipe-mod-azure-insights/pull/27))
  - [Network Security Group Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azure_network_security_group_dashboard) ([#22](https://github.com/turbot/steampipe-mod-azure-insights/pull/22))
  - [Network Security Group Detail Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azure_network_security_group_detail) ([#22](https://github.com/turbot/steampipe-mod-azure-insights/pull/22))
  - [Virtual Network Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azure_virtual_network_dashboard) ([#22](https://github.com/turbot/steampipe-mod-azure-insights/pull/22))
  - [Virtual Network Detail Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azure_virtual_network_detail) ([#22](https://github.com/turbot/steampipe-mod-azure-insights/pull/22))

## v0.2 [2022-03-31]

_What's new?_

- New dashboards added:
  - [Active Directory Group Age Report](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azuread_group_age_report) ([#21](https://github.com/turbot/steampipe-mod-azure-insights/pull/21))
  - [Active Directory Group Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azuread_group_dashboard) ([#21](https://github.com/turbot/steampipe-mod-azure-insights/pull/21))
  - [Active Directory User Age Report](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azuread_user_age_report) ([#21](https://github.com/turbot/steampipe-mod-azure-insights/pull/21))
  - [Active Directory User Dashboard](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azuread_user_dashboard) ([#21](https://github.com/turbot/steampipe-mod-azure-insights/pull/21))
  - [Key Vault Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azure_key_vault_detail) ([#16](https://github.com/turbot/steampipe-mod-azure-insights/pull/16))
  - [SQL Database Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azure_sql_database_detail) ([#18](https://github.com/turbot/steampipe-mod-azure-insights/pull/18))
  - [SQL Server Detail](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards/dashboard.azure_sql_server_detail) ([#15](https://github.com/turbot/steampipe-mod-azure-insights/pull/15))

## v0.1 [2022-03-21]

_What's new?_

New dashboards, reports, and details for the following services:
- Compute
- Key Vault
- SQL
- Storage

# Azure Insights Mod for Powerpipe

> [!IMPORTANT]
> [Powerpipe](https://powerpipe.io) is now the preferred way to run this mod! [Migrating from Steampipe →](https://powerpipe.io/blog/migrating-from-steampipe)
>
> All v0.x versions of this mod will work in both Steampipe and Powerpipe, but v1.0.0 onwards will be in Powerpipe format only.

An Azure dashboarding tool that can be used to view dashboards and reports across all of your Azure accounts.

![image](https://raw.githubusercontent.com/turbot/steampipe-mod-azure-insights/main/docs/images/azure_storage_account_dashboard.png)

## Overview

Dashboards can help answer questions like:

- How many resources do I have?
- How old are my resources?
- Are there any publicly accessible resources?
- Is encryption enabled and what keys are used for encryption?
- Is versioning enabled?
- What are the relationships between closely connected resources like compute virtual machines, disks, snapshots, and network?

Dashboards are available for Compute, Key Vault, SQL, and Storage services.

## Documentation

- **[Dashboards →](https://hub.powerpipe.io/mods/turbot/azure_insights/dashboards)**

## Getting Started

### Installation

Install Powerpipe (https://powerpipe.io/downloads), or use Brew:

```sh
brew install turbot/tap/powerpipe
```

This mod also requires [Steampipe](https://steampipe.io) with the [Azure plugin](https://hub.steampipe.io/plugins/turbot/azure) and the [Azure Active Directory plugin](https://hub.steampipe.io/plugins/turbot/azuread) as the data source. Install Steampipe (https://steampipe.io/downloads), or use Brew:

```sh
brew install turbot/tap/steampipe
steampipe plugin install azure
steampipe plugin install azuread
```

Steampipe will automatically use your default Azure and Azure Active Directory credentials. Optionally, you can [setup multiple subscriptions](https://hub.steampipe.io/plugins/turbot/azure#multi-subscription-connections) for Azure or [customize Azure credentials](https://hub.steampipe.io/plugins/turbot/azure#configuring-azure-credentials) or you can [setup multiple tenants](https://hub.steampipe.io/plugins/turbot/azuread#multi-tenant-connections) for Azure Active Directory or [customize Azure Active Directory credentials](https://hub.steampipe.io/plugins/turbot/azuread#configuring-azure-active-directory-credentials).

Finally, install the mod:

```sh
mkdir dashboards
cd dashboards
powerpipe mod init
powerpipe mod install github.com/turbot/steampipe-mod-azure-insights
```

### Browsing Dashboards

Start Steampipe as the data source:

```sh
steampipe service start
```

Start the dashboard server:

```sh
powerpipe server
```

Browse and view your dashboards at **http://localhost:9033**.

## Open Source & Contributing

This repository is published under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0). Please see our [code of conduct](https://github.com/turbot/.github/blob/main/CODE_OF_CONDUCT.md). We look forward to collaborating with you!

[Steampipe](https://steampipe.io) and [Powerpipe](https://powerpipe.io) are products produced from this open source software, exclusively by [Turbot HQ, Inc](https://turbot.com). They are distributed under our commercial terms. Others are allowed to make their own distribution of the software, but cannot use any of the Turbot trademarks, cloud services, etc. You can learn more in our [Open Source FAQ](https://turbot.com/open-source).

## Get Involved

**[Join #powerpipe on Slack →](https://turbot.com/community/join)**

Want to help but don't know where to start? Pick up one of the `help wanted` issues:

- [Powerpipe](https://github.com/turbot/powerpipe/labels/help%20wanted)
- [Azure Insights Mod](https://github.com/turbot/steampipe-mod-azure-insights/labels/help%20wanted)

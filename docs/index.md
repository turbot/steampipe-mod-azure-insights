---
repository: "https://github.com/turbot/steampipe-mod-azure-insights"
---

# Azure Insights Mod

Create dashboards and reports for your Azure resources using Steampipe.

<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-azure-insights/main/docs/images/azure_storage_account_dashboard.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-azure-insights/main/docs/images/azure_storage_account_age.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-azure-insights/main/docs/images/azure_activedirectory_group_detail.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-azure-insights/main/docs/images/azure_network_virtual_network_detail.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-azure-insights/main/docs/images/azure_compute_virtual_machine_detail.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/steampipe-mod-azure-insights/main/docs/images/azure_keyvault_detail.png" width="50%" type="thumbnail"/>

## Overview

Dashboards can help answer questions like:

- How many resources do I have?
- How old are my resources?
- Are there any publicly accessible resources?
- Is encryption enabled and what keys are used for encryption?
- Is versioning enabled?
- What are the relationships between closely connected resources like compute virtual machines, disks, snapshots, and network?

Dashboards are available for Compute, Key Vault, SQL, and Storage services.

## References

[Azure](https://azure.microsoft.com/) provides on-demand cloud computing platforms and APIs to authenticated customers on a metered pay-as-you-go basis.

[Steampipe](https://steampipe.io) is an open source CLI to instantly query cloud APIs using SQL.

[Steampipe Mods](https://steampipe.io/docs/reference/mod-resources#mod) are collections of `named queries`, codified `controls` that can be used to test current configuration of your cloud resources against a desired configuration, and `dashboards` that organize and display key pieces of information.

## Documentation

- **[Dashboards →](https://hub.steampipe.io/mods/turbot/azure_insights/dashboards)**

## Getting started

### Installation

Download and install Steampipe (https://steampipe.io/downloads). Or use Brew:

```sh
brew tap turbot/tap
brew install steampipe
```

Install the Azure and the Azure Active Directory plugins with [Steampipe](https://steampipe.io):

```sh
steampipe plugin install azure
steampipe plugin install azuread
```

Clone:

```sh
git clone https://github.com/turbot/steampipe-mod-azure-insights.git
cd steampipe-mod-azure-insights
```

### Usage

Start your dashboard server to get started:

```sh
steampipe dashboard
```

By default, the dashboard interface will then be launched in a new browser window at http://localhost:9194. From here, you can view dashboards and reports.

### Credentials

This mod uses the credentials configured in the [Steampipe Azure plugin](https://hub.steampipe.io/plugins/turbot/azure).

### Configuration

No extra configuration is required.

## Contributing

If you have an idea for additional dashboards or just want to help maintain and extend this mod ([or others](https://github.com/topics/steampipe-mod)) we would love you to join the community and start contributing.

- **[Join #steampipe on Slack →](https://turbot.com/community/join)** and hang out with other Mod developers.

Please see the [contribution guidelines](https://github.com/turbot/steampipe/blob/main/CONTRIBUTING.md) and our [code of conduct](https://github.com/turbot/steampipe/blob/main/CODE_OF_CONDUCT.md). All contributions are subject to the [Apache 2.0 open source license](https://github.com/turbot/steampipe-mod-azure-insights/blob/main/LICENSE).

Want to help but not sure where to start? Pick up one of the `help wanted` issues:

- [Steampipe](https://github.com/turbot/steampipe/labels/help%20wanted)
- [Azure Insights Mod](https://github.com/turbot/steampipe-mod-azure-insights/labels/help%20wanted)
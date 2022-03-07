---
repository: "https://github.com/turbot/steampipe-mod-azure-insights"
---

# Azure Insights Mod

Create dashboards and reports for your Azure resources using Steampipe.

## References

[Azure](https://azure.amazon.com/) provides on-demand cloud computing platforms and APIs to authenticated customers on a metered pay-as-you-go basis.

[Steampipe](https://steampipe.io) is an open source CLI to instantly query cloud APIs using SQL.

[Steampipe Mods](https://steampipe.io/docs/reference/mod-resources#mod) are collections of `named queries`, and codified `controls` that can be used to test current configuration of your cloud resources against a desired configuration.

## Documentation

- **[Benchmarks and controls →](https://hub.steampipe.io/mods/turbot/azure_insights/controls)**

## Getting started

### Installation

1) Install the Azure plugin:
```shell
steampipe plugin install azure
```

2) Clone this repo:
```sh
git clone https://github.com/turbot/steampipe-mod-azure-insights.git
cd steampipe-mod-azure-insights
```

### Usage

TODO

### Credentials

This mod uses the credentials configured in the [Steampipe Azure plugin](https://hub.steampipe.io/plugins/turbot/azure).

### Configuration

Several dashboards and reports have [input variables](https://steampipe.io/docs/using-steampipe/mod-variables) that can be configured to better match your environment and requirements. Each variable has a default defined in `steampipe.spvars`, but these can be overriden in several ways:

- Modify the `steampipe.spvars` file
- Remove or comment out the value in `steampipe.spvars`, after which Steampipe will prompt you for a value when running a query or check
- Pass in a value on the command line:
  ```shell
  steampipe check benchmark.mandatory --var 'mandatory_tags=["Application", "Environment", "Department", "Owner"]'
  ```
- Set an environment variable:
  ```shell
  SP_VAR_mandatory_tags='["Application", "Environment", "Department", "Owner"]' steampipe check control.ec2_instance_mandatory
  ```
  - Note: When using environment variables, if the variable is defined in `steampipe.spvars` or passed in through the command line, either of those will take precedence over the environment variable value. For more information on variable definition precedence, please see the link below.

These are only some of the ways you can set variables. For a full list, please see [Passing Input Variables](https://steampipe.io/docs/using-steampipe/mod-variables#passing-input-variables).

## Get involved

* Contribute: [GitHub Repo](https://github.com/turbot/steampipe-mod-azure-insights)

* Community: [Slack Channel](https://steampipe.io/community/join)

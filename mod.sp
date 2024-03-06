mod "azure_insights" {
  # Hub metadata
  title         = "Azure Insights"
  description   = "Create dashboards and reports for your Azure resources using Powerpipe and Steampipe."
  color         = "#0089D6"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/azure-insights.svg"
  categories    = ["azure", "dashboard", "public cloud"]

  opengraph {
    title       = "Powerpipe Mod for Azure Insights"
    description = "Create dashboards and reports for your Azure resources using Powerpipe and Steampipe."
    image       = "/images/mods/turbot/azure-insights-social-graphic.png"
  }

  require {
    plugin "azure" {
      min_version = "0.40.1"
    }
    plugin "azuread" {
      min_version = "0.8.3"
    }
  }
}

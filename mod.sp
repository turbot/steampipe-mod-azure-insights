mod "azure_insights" {
  # hub metadata
  title         = "Azure Insights"
  description   = "Create dashboards and reports for your Azure resources using Steampipe."
  color         = "#0089D6"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/azure-insights.svg"
  categories    = ["azure", "dashboard", "public cloud"]

  opengraph {
    title       = "Steampipe Mod for Azure Insights"
    description = "Create dashboards and reports for your Azure resources using Steampipe."
    image       = "/images/mods/turbot/azure-insights-social-graphic.png"
  }

  require {
    steampipe = "0.18.0"
    plugin "azure" {
      version = "0.40.1"
    }
    plugin "azuread" {
      version = "0.8.3"
    }
  }
}

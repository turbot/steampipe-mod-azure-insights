mod "azure_insights" {
  # hub metadata
  title         = "Azure Insights"
  description   = "Create dashboards and reports for your Azure resources using Steampipe."
  color         = "#FF9900"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/azure-insights.svg"
  categories    = ["azure", "insights", "public cloud"]

  opengraph {
    title       = "Steampipe Mod for Azure Insights"
    description = "Create dashboards and reports for your Azure resources using Steampipe."
    image       = "/images/mods/turbot/azure-insights-social-graphic.png"
  }
}

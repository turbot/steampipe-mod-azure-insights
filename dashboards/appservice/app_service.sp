locals {
  app_service_common_tags = {
    service = "Azure/AppService"
  }
}

category "azure_app_service_plan" {
  title = "App Service Plan"
  icon  = "text:ASP"
  color = local.storage_color
}

category "azure_app_service_web_app" {
  title = "App Service Web App"
  href  = "/azure_insights.dashboard.azure_app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  icon  = "text:WA"
  color = local.storage_color
}

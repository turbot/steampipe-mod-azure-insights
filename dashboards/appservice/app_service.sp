locals {
  app_service_common_tags = {
    service = "Azure/AppService"
  }
}

category "app_service_plan" {
  title = "App Service Plan"
  color = local.storage_color
  icon  = "settings_applications"
}

category "app_service_web_app" {
  title = "App Service Web App"
  color = local.storage_color
  href  = "/azure_insights.dashboard.app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  icon  = "apps"
}

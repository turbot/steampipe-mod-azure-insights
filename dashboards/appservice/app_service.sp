locals {
  app_service_common_tags = {
    service = "Azure/AppService"
  }
}

category "app_service_plan" {
  title = "App Service Plan"
  icon  = "settings_applications"
  color = local.storage_color
}

category "app_service_web_app" {
  title = "App Service Web App"
  href  = "/azure_insights.dashboard.app_service_web_app_detail?input.web_app_id={{.properties.'ID' | @uri}}"
  icon  = "code_blocks"
  color = local.storage_color
}

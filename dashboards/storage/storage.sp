locals {
  storage_common_tags = {
    service = "Azure/Storage"
  }
}

category "storage_container" {
  title = "Storage Container"
  icon  = "home_storage"
  color = local.storage_color
}

category "storage_queue" {
  title = "Storage Queue"
  icon  = "shelves"
  color = local.storage_color
}

category "storage_share_file" {
  title = "Storage Share File"
  icon  = "settings_system_daydream"
  color = local.storage_color
}

category "storage_storage_account" {
  title = "Storage Account"
  href  = "/azure_insights.dashboard.storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon  = "settings_account_box"
  color = local.storage_color
}

category "storage_table" {
  title = "Storage Table"
  icon  = "table_view"
  color = local.storage_color
}

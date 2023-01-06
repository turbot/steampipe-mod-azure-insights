locals {
  storage_common_tags = {
    service = "Azure/Storage"
  }
}

category "storage_container" {
  title = "Storage Container"
  color = local.storage_color
  icon  = "warehouse"
}

category "storage_queue" {
  title = "Storage Queue"
  color = local.storage_color
  icon  = "shelves"
}

category "storage_share_file" {
  title = "Storage Share File"
  color = local.storage_color
  icon  = "home_storage"
}

category "storage_storage_account" {
  title = "Storage Account"
  color = local.storage_color
  href  = "/azure_insights.dashboard.storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon  = "settings_account_box"
}

category "storage_table" {
  title = "Storage Table"
  color = local.storage_color
  icon  = "table_view"
}

locals {
  storage_common_tags = {
    service = "Azure/Storage"
  }
}

category "storage_container" {
  title = "Storage Container"
  icon  = "home-storage"
  color = local.storage_color
}

category "storage_queue" {
  title = "Storage Queue"
  icon  = "shelves"
  color = local.storage_color
}

category "storage_share_file" {
  title = "Storage Share File"
  icon  = "settings-system-daydream"
  color = local.storage_color
}

category "storage_storage_account" {
  title = "Storage Account"
  href  = "/azure_insights.dashboard.storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon  = "settings-account-box"
  color = local.storage_color
}

category "storage_table" {
  title = "Storage Table"
  icon  = "table-view"
  color = local.storage_color
}

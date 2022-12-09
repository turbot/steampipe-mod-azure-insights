locals {
  storage_common_tags = {
    service = "Azure/Storage"
  }
}

category "storage_container" {
  title = "Storage Container"
  icon  = "text:StorageContainer"
  color = local.storage_color
}

category "storage_queue" {
  title = "Storage Queue"
  icon  = "text:StorageQueue"
  color = local.storage_color
}

category "storage_share_file" {
  title = "Storage Share File"
  icon  = "text:StorageShareFile"
  color = local.storage_color
}

category "storage_storage_account" {
  title = "Storage Account"
  href  = "/azure_insights.dashboard.storage_account_detail?input.storage_account_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:archive-box"
  color = local.storage_color
}

category "storage_table" {
  title = "Storage Table"
  icon  = "text:StorageTable"
  color = local.storage_color
}

edge "monitor_diagnostic_setting_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(storage_account_id) as to_id
    from
      azure_diagnostic_setting
    where
      lower(id) = any($1);
  EOQ

  param "monitor_diagnostic_setting_ids" {}
}

edge "monitor_log_profile_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(storage_account_id) as to_id
    from
      azure_log_profile
    where
      lower(id) = any($1);
  EOQ

  param "monitor_log_profile_ids" {}
}

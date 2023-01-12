node "monitor_diagnostic_setting" {
  category = category.monitor_diagnostic_setting

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_diagnostic_setting
    where
      lower(id) = any($1);
  EOQ

  param "monitor_diagnostic_setting_ids" {}
}

node "monitor_log_profile" {
  category = category.monitor_log_profile

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_log_profile
    where
      lower(id) = any($1);
  EOQ

  param "monitor_log_profile_ids" {}
}

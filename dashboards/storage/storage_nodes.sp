node "storage_storage_account" {
  category = category.azure_storage_account

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
      azure_storage_account
    where
      lower(id) = any($1);
  EOQ

  param "storage_account_ids" {}
}
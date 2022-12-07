node "batch_account" {
  category = category.batch_account

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
      azure_batch_account
    where
      lower(id) = any($1);
  EOQ

  param "batch_account_ids" {}
}
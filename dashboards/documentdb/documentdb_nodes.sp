node "documentdb_cosmosdb_account" {
  category = category.documentdb_cosmosdb_account

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', lower(id),
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_cosmosdb_account
    where
      lower(id) = any($1);
  EOQ

  param "documentdb_cosmosdb_account_ids" {}
}
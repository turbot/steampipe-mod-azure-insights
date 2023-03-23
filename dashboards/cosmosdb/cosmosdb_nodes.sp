node "cosmosdb_account" {
  category = category.cosmosdb_account

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

  param "cosmosdb_account_ids" {}
}

node "cosmosdb_mongo_database" {
  category = category.cosmosdb_mongo_database

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
      azure_cosmosdb_mongo_database
    where
      lower(id) = any($1);
  EOQ

  param "cosmosdb_mongo_database_ids" {}
}

node "cosmosdb_sql_database" {
  category = category.cosmosdb_sql_database

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
      azure_cosmosdb_sql_database
    where
      lower(id) = any($1);
  EOQ

  param "cosmosdb_mongo_database_ids" {}
}
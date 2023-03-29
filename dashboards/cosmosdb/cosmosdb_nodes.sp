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

// /subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/demo/providers/Microsoft.DocumentDB/databaseAccounts/demo-insight-mongo-acc/mongodbDatabases/test-mongo-db/collections/test
node "cosmosdb_mongo_collection" {
  category = category.cosmosdb_mongo_collection

  sql = <<-EOQ
    select
      lower(c.id) as id,
      c.title as title,
      jsonb_build_object(
        'Name', c.name,
        'ID', lower(c.id),
        'Type', c.type,
        'Resource Group', c.resource_group,
        'Subscription ID', c.subscription_id
      ) as properties
    from
      azure_cosmosdb_mongo_collection c,
      azure_cosmosdb_mongo_database d
    where
      c.database_name = d.name
      and c.account_name in (select account_name from azure_cosmosdb_mongo_database where lower(id) = any($1))
      and lower(d.id) = any($1)
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

  param "cosmosdb_sql_database_ids" {}
}

node "cosmosdb_restorable_database_account" {
  category = category.cosmosdb_restorable_database_account

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
      azure_cosmosdb_restorable_database_account
    where
      lower(id) = any($1);
  EOQ

  param "restorable_database_account_ids" {}
}
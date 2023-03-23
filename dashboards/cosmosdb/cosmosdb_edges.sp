edge "cosmosdb_account_to_key_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(split_part(k.id, '/keys/', 1)) as to_id
    from
      azure_cosmosdb_account a,
      azure_key_vault_key k
    where
      a.key_vault_key_uri = k.key_uri
      and lower(a.id) = any($1);
  EOQ

  param "cosmosdb_account_ids" {}
}

edge "cosmosdb_account_to_key_vault_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(split_part(k.id, '/keys/', 1)) as from_id,
      lower(k.id) as to_id
    from
      azure_cosmosdb_account a,
      azure_key_vault_key k
    where
      a.key_vault_key_uri = k.key_uri
      and lower(a.id) = any($1);
  EOQ

  param "cosmosdb_account_ids" {}
}

edge "cosmosdb_account_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    with cosmosdb_account as (
      select
        key_vault_key_uri as uri,
        id
      from
        azure_cosmosdb_account
    )
    select
      lower(s.id) as from_id,
      lower(v.id) as to_id
    from
      azure_key_vault_key_version as v
      left join cosmosdb_account as s on lower(v.key_uri_with_version) = lower(s.uri)
    where
      lower(s.id) = any($1);
  EOQ

  param "cosmosdb_account_ids" {}
}

edge "cosmosdb_account_to_network_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(r ->> 'id') as to_id
    from
      azure_cosmosdb_account a,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(a.id) = any($1);
  EOQ

  param "cosmosdb_account_ids" {}
}

edge "cosmosdb_account_to_cosmosdb_mongo_database" {
  title = "database"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(d.id) as to_id
    from
      azure_cosmosdb_account a,
      azure_cosmosdb_mongo_database d
    where
      d.account_name = a.name
      and lower(a.id) = any($1);
  EOQ

  param "cosmosdb_account_ids" {}
}

edge "cosmosdb_mongo_database_to_cosmosdb_mongo_collection" {
  title = "collection"

  sql = <<-EOQ
    select
      lower(d.id) as from_id,
      lower(c.id) as to_id
    from
      azure_cosmosdb_mongo_database d,
      azure_cosmosdb_mongo_collection c
    where
      d.name = c.database_name
      and lower(d.id) = any($1);
  EOQ

  param "cosmosdb_mongo_database_ids" {}
}

edge "cosmosdb_account_to_cosmosdb_sql_database" {
  title = "database"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(d.id) as to_id
    from
      azure_cosmosdb_account a,
      azure_cosmosdb_sql_database d
    where
      d.account_name = a.name
      and lower(a.id) = any($1);
  EOQ

  param "cosmosdb_account_ids" {}
}

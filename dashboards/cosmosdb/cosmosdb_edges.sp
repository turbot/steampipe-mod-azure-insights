edge "cosmosdb_account_to_key_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(split_part(k.id, '/keys/', 1)) as to_id
    from
      azure_cosmosdb_account a
      join unnest($1::text[]) as i on lower(a.id) = i and a.subscription_id = split_part(i, '/', 3),
      azure_key_vault_key k
    where
      a.key_vault_key_uri = k.key_uri;
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
      azure_cosmosdb_account a
      join unnest($1::text[]) as i on lower(a.id) = i and a.subscription_id = split_part(i, '/', 3),
      azure_key_vault_key k
    where
      a.key_vault_key_uri = k.key_uri;
  EOQ

  param "cosmosdb_account_ids" {}
}

edge "cosmosdb_account_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    with cosmosdb_account as (
      select
        key_vault_key_uri as uri,
        subscription_id,
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
      join unnest($1::text[]) as i on lower(s.id) = i and s.subscription_id = split_part(i, '/', 3);
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
      azure_cosmosdb_account a
      join unnest($1::text[]) as i on lower(a.id) = i and a.subscription_id = split_part(i, '/', 3),
      jsonb_array_elements(virtual_network_rules) as r;
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
      azure_cosmosdb_account a
      join unnest($1::text[]) as i on lower(a.id) = i and a.subscription_id = split_part(i, '/', 3),
      azure_cosmosdb_mongo_database d
    where
      d.account_name = a.name;
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
      azure_cosmosdb_mongo_database d
      join unnest($1::text[]) as i on lower(d.id) = i and d.subscription_id = split_part(i, '/', 3),
      azure_cosmosdb_mongo_collection c
    where
      d.name = c.database_name;
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
      azure_cosmosdb_account a
      join unnest($1::text[]) as i on lower(a.id) = i and a.subscription_id = split_part(i, '/', 3),
      azure_cosmosdb_sql_database d
    where
      d.account_name = a.name;
  EOQ

  param "cosmosdb_account_ids" {}
}

edge "cosmosdb_account_to_cosmosdb_restorable_database_account" {
  title = "database account"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(ra.id) as to_id
    from
      azure_cosmosdb_restorable_database_account ra,
      azure_cosmosdb_account a
    where
      ra.account_name =  a.name
      and ra.subscription_id = a.subscription_id
      and lower(a.id) = any($1);
  EOQ

  param "cosmosdb_account_ids" {}
}

edge "cosmosdb_restorable_database_account_to_cosmosdb_account" {
  title = "restored from"

  sql = <<-EOQ
    select
      lower(ra.id) as from_id,
      lower(a.id) as to_id
    from
      azure_cosmosdb_restorable_database_account ra
      join unnest($1::text[]) as i on lower(ra.id) = i and ra.subscription_id = split_part(i, '/', 3),
      azure_cosmosdb_account a
    where
      ra.id =  a.restore_parameters ->> 'restoreSource';
  EOQ

  param "restorable_database_account_ids" {}
}

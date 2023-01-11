edge "sql_database_to_mssql_elasticpool" {
  title = "elasticpool"
  sql   = <<-EOQ
    with sql_pools as (
      select
        id,
        name
      from
        azure_mssql_elasticpool
    )
    select
      lower(sp.id) as to_id,
      lower(db.id) as from_id
    from
      azure_sql_database as db,
      sql_pools as sp
    where
      lower(db.id) = any($1)
      and lower(sp.name) = lower(db.elastic_pool_name);
  EOQ
  param "sql_database_ids" {}
}

edge "sql_server_to_key_vault" {
  title = "key vault"

  sql = <<-EOQ
    with key_vault as (
      select
        lower(id) as to_id,
        name as key_vault_name
      from
        azure_key_vault
      where
        name in (
          select
            split_part(ep ->> 'serverKeyName','_',1) as key_vault_name
          from
            azure_sql_server,
            jsonb_array_elements(encryption_protector) as ep
          where
            lower(id) = any($1)
            and ep ->> 'kind' = 'azurekeyvault'
        )
    )
    select
      lower(id) as from_id,
      kv.to_id as to_id
    from
      azure_sql_server,
      key_vault as kv
    where
      lower(id) = any($1);
  EOQ

  param "sql_server_ids" {}
}

edge "sql_server_to_key_vault_key" {
  title = "encrypted with"

  sql = <<-EOQ
    with all_keys as (
      select
        lower(id) as id,
        name as key_vault_key_name,
        vault_name as key_vault_name,
        concat('/subscriptions/',subscription_id,'/resourceGroups/',resource_group,'/providers/Microsoft.KeyVault/vaults/',vault_name) as key_vault_id
      from
        azure_key_vault_key
    ),
    attached_keys as (
      select
        split_part(ep ->> 'serverKeyName','_',1) as key_vault_name,
        split_part(ep ->> 'serverKeyName','_',2) as key_vault_key_name
      from
        azure_sql_server,
        jsonb_array_elements(encryption_protector) as ep
      where
        lower(id) = any($1)
        and ep ->> 'kind' = 'azurekeyvault'
    )
    select
      lower(b.id) as to_id,
      lower(b.key_vault_id) as from_id
    from
      attached_keys as a
      left join all_keys as b on lower(a.key_vault_key_name) = lower(b.key_vault_key_name);
  EOQ

  param "sql_server_ids" {}
}

edge "sql_server_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    with sql_server as (
      select
        ep ->> 'uri' as uri,
        id
      from
        azure_sql_server,
        jsonb_array_elements(encryption_protector) as ep
      where
        ep ->> 'kind' = 'azurekeyvault'
    )
    select
      lower(s.id) as from_id,
      lower(v.id) as to_id
    from
      azure_key_vault_key_version as v
      left join sql_server as s on lower(v.key_uri_with_version) = lower(s.uri)
    where
      lower(s.id) = any($1);
  EOQ

  param "sql_server_ids" {}
}

edge "sql_server_to_mssql_elasticpool" {
  title = "elastic pool"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(e.id) as to_id
    from
      azure_mssql_elasticpool as e
      left join azure_sql_server as s on lower(e.server_name) = lower(s.name)
    where
      lower(s.id) = any($1);;
  EOQ

  param "sql_server_ids" {}
}

edge "sql_server_to_network_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      lower(id) as from_id,
      lower(vnr -> 'properties' ->> 'virtualNetworkSubnetId') as to_id
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as vnr
    where
      lower(id) = any($1);
  EOQ

  param "sql_server_ids" {}
}

edge "sql_server_to_sql_database" {
  title = "database"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(d.id) as to_id
    from
      azure_sql_database as d,
      azure_sql_server as s
    where
      lower(d.server_name) = s.name
      and lower(s.id) = any($1);
  EOQ

  param "sql_server_ids" {}
}

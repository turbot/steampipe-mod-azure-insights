edge "key_vault_to_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(s.id) as to_id
      from
        azure_key_vault as v,
        jsonb_array_elements(network_acls -> 'virtualNetworkRules') as r
        left join azure_subnet as s on lower(s.id) = lower(r ->> 'id')
      where
        lower(v.id) = any($1);
  EOQ

  param "key_vault_ids" {}
}

edge "key_vault_to_key" {
  title = "key"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(k.id) as to_id
    from
      azure_key_vault as v,
      azure_key_vault_key as k
    where
      v.name = k.vault_name
    and
      lower(v.id) = any($1);
  EOQ

  param "key_vault_ids" {}
}

edge "key_vault_to_secret" {
  title = "secret"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(s.id) as to_id
    from
      azure_key_vault as v,
      azure_key_vault_secret as s
    where
      v.name = s.vault_name
    and
      lower(v.id) = any($1);
  EOQ

  param "key_vault_ids" {}
}

edge "key_vault_key_version_to_key" {
  title = "key"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(v.key_id) as to_id
    from
      azure_key_vault_key_version as v
    where
      lower(v.key_id) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "key_vault_key_to_key_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      lower(k.id) as from_id,
      lower(v.id) as to_id
    from
      azure_key_vault_key as k
      left join azure_key_vault as v on v.name = k.vault_name
    where
      lower(k.id) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "compute_disk_encryption_set_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(v.id) as to_id
    from
      azure_key_vault_key_version as v
      left join azure_compute_disk_encryption_set as s on s.active_key_url = v.key_uri_with_version
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "container_registry_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(r.id) as from_id,
      lower(v.id) as to_id
    from
      azure_key_vault_key as k
      left join azure_container_registry as r on r.encryption -> 'keyVaultProperties' ->> 'keyIdentifier' = k.key_uri
      left join azure_key_vault_key_version as v on v.key_uri_with_version = k.key_uri_with_version
    where
      lower(k.id) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "sql_server_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    with sql_server as (
      select
        ep ->> 'uri' as uri,
        id,
        title,
        name,
        type,
        region,
        resource_group,
        subscription_id
      from
        azure_sql_server,
        jsonb_array_elements(encryption_protector) as ep
      where
        ep ->> 'kind' = 'azurekeyvault'
    )
    select
      s.id as from_id,
      v.id as to_id
    from
      azure_key_vault_key_version as v
      left join sql_server as s on v.key_uri_with_version = s.uri
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "eventhub_namespace_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(n.id) as from_id,
      lower(k.id) as to_id
    from
      azure_eventhub_namespace as n,
      jsonb_array_elements(encryption -> 'keyVaultProperties') as p
      left join azure_key_vault_key as k on p ->> 'keyName' = k.name
      left join azure_key_vault as v on v.name = k.vault_name
    where
      k.resource_group = v.resource_group
      and k.resource_group = n.resource_group
      and lower(k.id) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "storage_account_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(v.id) as to_id
    from
      azure_storage_account as s
      left join azure_key_vault_key_version as v on lower(s.encryption_key_vault_properties_key_current_version_id) = lower(v.key_uri_with_version)
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "servicebus_namespace_to_key_vault_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(n.id) as from_id,
      lower(k.id) as to_id
    from
      azure_servicebus_namespace as n,
      jsonb_array_elements(encryption -> 'keyVaultProperties') as p
      left join azure_key_vault_key as k on p ->> 'keyName' = k.name
      left join azure_key_vault as v on v.name = k.vault_name
    where
      k.resource_group = v.resource_group
      and k.resource_group = n.resource_group
      and lower(k.id) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

edge "postgresql_server_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(v.id) as to_id
    from
      azure_postgresql_server as s,
      jsonb_array_elements(server_keys) as sk
      left join azure_key_vault_key_version as v on lower(sk ->> 'ServerKeyUri') = lower(v.key_uri_with_version)
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}


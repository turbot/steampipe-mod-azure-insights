node "key_vault" {
  category = category.azure_key_vault

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Vault Name', name,
        'Vault Id', id
      ) as properties
    from
      azure_key_vault
    where
      lower(id) = any($1);
  EOQ

  param "key_vault_ids" {}
}

node "key_vault_secret" {
  category = category.azure_key_vault_secret

  sql = <<-EOQ
    select
      s.title as title,
      s.id as id,
      jsonb_build_object(
        'Secret Name', s.name,
        'Secret Id', s.id,
        'Created At', s.created_at,
        'Expires At', s.expires_at,
        'Vault Name', s.vault_name
      ) as properties
    from
      azure_key_vault_secret as s
      left join azure_key_vault as v on v.name = s.vault_name
    where
      lower(v.id) = any($1);
  EOQ

  param "key_vault_ids" {}
}

node "key_vault_key_version" {
  category = category.azure_key_vault_key_verison

  sql = <<-EOQ
    select
      lower(v.id) as id,
      case when k.key_uri_with_version = v.key_uri_with_version then 'current' || ' ['|| left(v.title,8) || ']' else 'older' || ' ['|| left(v.title,8) || ']' end as title,
      jsonb_build_object(
        'Version Name', v.name,
        'Key Name', v.key_name,
        'Key URI', v.key_uri,
        'ID', v.id,
        'Vault Name', v.vault_name
      ) as properties
    from
      azure_key_vault_key_version as v
      left join azure_key_vault_key as k on v.key_uri = k.key_uri
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

node "key_vault_key" {
  category = category.azure_key_vault_key

  sql = <<-EOQ
    select
      lower(id) as id,
      name as title,
      jsonb_build_object(
        'Key Name', name,
        'Key ID', id,
        'Vault Name', vault_name
      ) as properties
    from
      azure_key_vault_key
    where
      lower(id) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

node "key_vault_key_to_key_vault" {
  category = category.azure_key_vault

  sql = <<-EOQ
    select
      lower(v.id) as id,
      v.name as title,
      jsonb_build_object(
        'Name', v.name,
        'ID', v.id,
        'Type', v.type,
        'Purge Protection Enabled', v.purge_protection_enabled
      ) as properties
    from
      azure_key_vault_key as k
      left join azure_key_vault as v on v.name = k.vault_name
    where
      k.id = $1;
  EOQ

  param "key_vault_key_ids" {}
}

node "key_vault_key_version_compute_disk_encryption_set" {
  category = category.azure_compute_disk_encryption_set

  sql = <<-EOQ
    select
      lower(s.id) as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Provisioning State', s.provisioning_state,
        'Encryption Type', s.encryption_type,
        'Type', s.type,
        'Region', s.region,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_key_vault_key_version as v
      left join azure_compute_disk_encryption_set as s on s.active_key_url = v.key_uri_with_version
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

node "key_vault_key_version_container_registry" {
  category = category.azure_container_registry

  sql = <<-EOQ
    select
      lower(r.id) as id,
      r.title as title,
      jsonb_build_object(
        'Name', r.name,
        'ID', r.id,
        'Provisioning State', r.provisioning_state,
        'Type', r.type,
        'Region', r.region,
        'Resource Group', r.resource_group,
        'Subscription ID', r.subscription_id
      ) as properties
    from
      azure_key_vault_key as k
      left join azure_container_registry as r on r.encryption -> 'keyVaultProperties' ->> 'keyIdentifier' = k.key_uri
      left join azure_key_vault_key_version as v on v.key_uri_with_version = k.key_uri_with_version
    where
      lower(k.id) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

node "key_vault_key_version_sql_server" {
  category = category.sql_server

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
      lower(s.id) as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Type', s.type,
        'Region', s.region,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_key_vault_key_version as v
      left join sql_server as s on v.key_uri_with_version = s.uri
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

node "key_vault_key_version_eventhub_namespace" {
  category = category.azure_eventhub_namespace

  sql = <<-EOQ
    select
      lower(n.id) as id,
      n.title as title,
      jsonb_build_object(
        'Name', n.name,
        'ID', n.id,
        'Provisioning State', n.provisioning_state,
        'Type', n.type,
        'Region', n.region,
        'Resource Group', n.resource_group,
        'Subscription ID', n.subscription_id
      ) as properties
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

node "azure_key_vault_key_version_from_storage_account_node" {
  category = category.azure_storage_account

  sql = <<-EOQ
    select
      s.id as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Type', s.type,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_storage_account as s
      left join azure_key_vault_key_version as v on lower(s.encryption_key_vault_properties_key_current_version_id) = lower(v.key_uri_with_version)
    where
      lower(split_part(v.id, '/versions', 1)) = lower($1);
  EOQ

  param "id" {}
}

node "key_vault_key_version_servicebus_namespace" {
  category = category.azure_servicebus_namespace

  sql = <<-EOQ
    select
      lower(n.id) as id,
      n.title as title,
      jsonb_build_object(
        'Name', n.name,
        'ID', n.id,
        'Provisioning State', n.provisioning_state,
        'Type', n.type,
        'Region', n.region,
        'Resource Group', n.resource_group,
        'Subscription ID', n.subscription_id
      ) as properties
    from
      azure_servicebus_namespace as n,
      jsonb_array_elements(encryption -> 'keyVaultProperties') as p
      left join azure_key_vault_key as k on p ->> 'keyName' = k.name
      left join azure_key_vault as v on v.name = k.vault_name
    where
      lower(k.resource_group) = lower(v.resource_group)
      and lower(k.resource_group) = lower(n.resource_group)
      and lower(k.id) = any($1);

  EOQ

  param "key_vault_key_ids" {}
}

node "key_vault_key_version_postgresql_server" {
  category = category.azure_postgresql_server

  sql = <<-EOQ
    select
      lower(s.id) as id,
      s.title as title,
      jsonb_build_object(
        'Name', s.name,
        'ID', s.id,
        'Type', s.type,
        'Region', s.region,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_postgresql_server as s,
      jsonb_array_elements(server_keys) as sk
      left join azure_key_vault_key_version as v on lower(sk ->> 'ServerKeyUri') = lower(v.key_uri_with_version)
    where
      lower(split_part(v.id, '/versions', 1)) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}
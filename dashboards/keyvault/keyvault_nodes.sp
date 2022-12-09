node "key_vault_key" {
  category = category.key_vault_key

  sql = <<-EOQ
    select
      lower(id) as id,
      name as title,
      jsonb_build_object(
        'Key Name', name,
        'Key ID', lower(id),
        'Vault Name', vault_name,
        'Key Type', key_type,
        'Key Size', key_size,
        'Created At', created_at,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Type', type,
        'Region', region
      ) as properties
    from
      azure_key_vault_key
    where
      lower(id) = any($1);
  EOQ

  param "key_vault_key_ids" {}
}

node "key_vault_key_version" {
  category = category.key_vault_key_verison

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

node "key_vault_secret" {
  category = category.key_vault_secret

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

  param "key_vault_vault_ids" {}
}

node "key_vault_vault" {
  category = category.key_vault

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Vault Name', name,
        'ID', lower(id),
        'Purge Protection Enabled', (purge_protection_enabled)::text,
        'SKU Family', sku_family,
        'Soft Delete Enabled', soft_delete_enabled,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Type', type,
        'Region', region
      ) as properties
    from
      azure_key_vault
    where
      lower(id) = any($1);
  EOQ

  param "key_vault_vault_ids" {}
}

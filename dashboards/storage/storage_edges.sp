edge "storage_storage_account_to_key_vault_key" {
  title = "key"

  sql = <<-EOQ
    select
      lower(k.id )as from_id,
      lower(key.id) as to_id
    from
      azure_storage_account as a
      left join azure_key_vault as k on a.encryption_key_vault_properties_key_vault_uri = trim(k.vault_uri, '/')
      left join azure_key_vault_key_version as v on lower(v.key_uri_with_version) = lower(a.encryption_key_vault_properties_key_current_version_id)
      left join azure_key_vault_key as key on lower(key.key_uri) = lower(v.key_uri)
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "storage_storage_account_to_key_vault_key_version" {
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

edge "storage_storage_account_to_key_vault_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(k.id) as to_id
    from
      azure_storage_account as a
      left join azure_key_vault as k on a.encryption_key_vault_properties_key_vault_uri = trim(k.vault_uri, '/')
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "storage_storage_account_to_network_subnet" {
  title = "subnet"

  sql = <<-EOQ
    with subnet_list as (
      select
        id as storage_account_id,
        r ->> 'id' as subnet_id
      from
        azure_storage_account,
        jsonb_array_elements(virtual_network_rules) as r
      where
        lower(id) = any($1)
    )
    select
      lower(l.storage_account_id) as from_id,
      lower(l.subnet_id) as to_id
    from
      subnet_list as l
      left join azure_subnet as s on lower(l.subnet_id) = lower(s.id);
  EOQ

  param "storage_account_ids" {}
}

edge "storage_storage_account_to_storage_storage_container" {
  title = "storage container"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(c.id) as to_id
    from
      azure_storage_container as c
      left join azure_storage_account as a on a.name = c.account_name
      and a.resource_group = c.resource_group
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "storage_storage_account_to_storage_storage_queue" {
  title = "storage queue"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(q.id) as to_id
    from
      azure_storage_account as a
      left join azure_storage_queue as q on q.storage_account_name = a.name
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "storage_storage_account_to_storage_storage_share_file" {
  title = "storage share file"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(f.id) as to_id
    from
      azure_storage_share_file as f
      left join azure_storage_account as a on a.name = f.storage_account_name
      and a.resource_group = f.resource_group
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

edge "storage_storage_account_to_storage_storage_table" {
  title = "storage table"

  sql = <<-EOQ
    select
      lower(a.id) as from_id,
      lower(t.id) as to_id
    from
      azure_storage_account as a
      left join azure_storage_table as t on t.storage_account_name = a.name
    where
      lower(a.id) = any($1);
  EOQ

  param "storage_account_ids" {}
}

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

edge "key_vault_key_to_key_vault" {
  title = "key vault"

  sql = <<-EOQ
    select
      lower(k.id) as from_id,
      lower(v.id) as to_id
    from
      azure_key_vault_key as k
      left join azure_key_vault as v on v.name = k.vault_name
      join unnest($1::text[]) as i on lower(k.id) = i and k.subscription_id = split_part(i, '/', 3);
  EOQ

  param "key_vault_key_ids" {}
}

edge "key_vault_key_version_to_key_vault_key" {
  title = "key"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(v.key_id) as to_id
    from
      azure_key_vault_key_version as v
      join unnest($1::text[]) as i on lower(v.key_id) = i and v.subscription_id = split_part(i, '/', 3);
  EOQ

  param "key_vault_key_ids" {}
}

edge "key_vault_to_key_vault_key" {
  title = "key"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(k.id) as to_id
    from
      azure_key_vault as v
      join unnest($1::text[]) as i on lower(v.id) = i and v.subscription_id = split_part(i, '/', 3),
      azure_key_vault_key as k
    where
      v.name = k.vault_name;
  EOQ

  param "key_vault_vault_ids" {}
}

edge "key_vault_to_key_vault_secret" {
  title = "secret"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(s.id) as to_id
    from
      azure_key_vault as v
      join unnest($1::text[]) as i on lower(v.id) = i and v.subscription_id = split_part(i, '/', 3),
      azure_key_vault_secret as s
    where
      v.name = s.vault_name;
  EOQ

  param "key_vault_vault_ids" {}
}

edge "key_vault_to_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(s.id) as to_id
      from
        azure_key_vault as v
        join unnest($1::text[]) as i on lower(v.id) = i and v.subscription_id = split_part(i, '/', 3),
        jsonb_array_elements(network_acls -> 'virtualNetworkRules') as r
        left join azure_subnet as s on lower(s.id) = lower(r ->> 'id');
  EOQ

  param "key_vault_vault_ids" {}
}

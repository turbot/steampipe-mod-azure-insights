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
      join unnest($1::text[]) as i on lower(r.id) = i and r.subscription_id = split_part(i, '/', 3);
  EOQ

  param "container_registry_ids" {}
}
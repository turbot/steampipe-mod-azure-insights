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
      and lower(n.id) = any($1);
  EOQ

  param "eventhub_namespace_ids" {}
}
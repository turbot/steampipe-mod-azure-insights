edge "postgresql_server_to_key_vault_key_version" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(v.id) as to_id
    from
      azure_postgresql_server as s
      join unnest($1::text[]) as i on lower(s.id) = i and s.subscription_id = split_part(i, '/', 3),
      jsonb_array_elements(server_keys) as sk
      left join azure_key_vault_key_version as v on lower(sk ->> 'ServerKeyUri') = lower(v.key_uri_with_version);
  EOQ

  param "postgresql_server_ids" {}
}

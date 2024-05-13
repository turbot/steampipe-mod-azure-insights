node "postgresql_server" {
  category = category.postgresql_server

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_postgresql_server
      join unnest($1::text[]) as i on lower(id) = i and subscription_id = split_part(i, '/', 1);
  EOQ

  param "postgresql_server_ids" {}
}
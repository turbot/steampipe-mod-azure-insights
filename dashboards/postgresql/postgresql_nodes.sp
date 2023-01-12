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
    where
      lower(id) = any($1);
  EOQ

  param "postgresql_server_ids" {}
}
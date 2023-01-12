node "mssql_elasticpool" {
  category = category.mssql_elasticpool

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      json_build_object(
        'Edition', edition,
        'State', state,
        'Zone Redundant', zone_redundant,
        'Type', type,
        'ID', id
      ) as properties
    from
      azure_mssql_elasticpool
    where
      lower(id) = any($1)
  EOQ

  param "mssql_elasticpool_ids" {}
}

node "sql_database" {
  category = category.sql_database

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      json_build_object(
        'ID', lower(id),
        'Location', location,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id,
        'Database ID', database_id,
        'status', status,
        'Kind', kind,
        'Type', type,
        'Zone Redundant', zone_redundant,
        'Default Secondary Location', default_secondary_location
      ) as properties
    from
      azure_sql_database
    where
      lower(id) = any($1);
  EOQ

  param "sql_database_ids" {}
}

node "sql_server" {
  category = category.sql_server

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', lower(id),
        'Name', name,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id,
        'Fully Qualified Domain Name', fully_qualified_domain_name,
        'Type', type
      ) as properties
    from
      azure_sql_server
    where
      lower(id) = any($1);
  EOQ

  param "sql_server_ids" {}
}

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

node "sql_database_mssql_elasticpool" {
  category = category.mssql_elasticpool

  sql = <<-EOQ
    select
      lower(sp.id) as id,
      sp.title as title,
      json_build_object(
        'Edition', sp.edition,
        'State', sp.state,
        'Zone Redundant', sp.zone_redundant,
        'Type', sp.type,
        'ID', sp.id
      ) as properties
    from
      azure_sql_database as db
      left join azure_mssql_elasticpool as sp on lower(sp.name) = lower(db.elastic_pool_name)
    where
      sp.id is not null
      and lower(db.id) = any($1)
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

node "sql_server_mssql_elasticpool" {
  category = category.mssql_elasticpool

  sql = <<-EOQ
    select
      lower(e.id) as id,
      e.title as title,
      json_build_object(
        'Name', e.name,
        'Type', e.type,
        'ID', e.id,
        'Resource Group', e.resource_group,
        'Subscription ID', e.subscription_id,
        'Edition', e.edition
      ) as properties
    from
      azure_mssql_elasticpool as e
      left join azure_sql_server as s on lower(e.server_name) = lower(s.name)
    where
      lower(s.id) = any($1);;
  EOQ

  param "sql_server_ids" {}
}

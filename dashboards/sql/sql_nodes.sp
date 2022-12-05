node "sql_server" {
  category = category.sql_server

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', id,
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

node "network_private_endpoint" {
  category = category.private_endpoint_connection

  sql = <<-EOQ
    select
      lower(pec ->> 'PrivateEndpointConnectionId') as id,
      pec ->> 'PrivateEndpointConnectionName' as title,
      json_build_object(
        'Private Endpoint Connection Name', pec ->> 'PrivateEndpointConnectionName',
        'Type', pec ->> 'PrivateEndpointConnectionType',
        'Provisioning State', pec ->> 'ProvisioningState'
      ) as properties
    from
      azure_sql_server,
      jsonb_array_elements(private_endpoint_connections) as pec
    where
      lower(id) = any($1);
  EOQ

  param "sql_server_ids" {}
}

node "sql_database" {
  category = category.sql_database

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      json_build_object(
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
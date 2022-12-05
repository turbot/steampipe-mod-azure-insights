
node "network_network_interface" {
  category = category.azure_network_interface

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_network_interface
    where
      lower(id) = any($1);
  EOQ

  param "network_interface_ids" {}
}

node "network_public_ip" {
  category = category.azure_public_ip

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_public_ip
    where
      lower(id) = any($1);
  EOQ

  param "network_public_ip_ids" {}
}

node "network_network_security_group" {
  category = category.azure_network_security_group

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_network_security_group
    where
      lower(id) = any($1);
  EOQ

  param "network_security_group_ids" {}
}

node "network_security_group_network_watcher_flow_log" {
  category = category.azure_network_watcher_flow_log

  sql = <<-EOQ
    select
      lower(fl.id) as id,
      fl.title as title,
      jsonb_build_object(
        'Name', fl.name,
        'ID', fl.id,
        'Region', fl.region,
        'Resource Group', fl.resource_group,
        'Subscription ID', fl.subscription_id
      ) as properties
    from
      azure_network_security_group as nsg,
      jsonb_array_elements(flow_logs) as f
      left join azure_network_watcher_flow_log as fl on lower(fl.id) = lower(f->> 'id')
    where
      lower(nsg.id) = any($1);
  EOQ

  param "network_security_group_ids" {}
}

node "network_subnet" {
  category = category.azure_subnet

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'Etag', etag,
        'Type', type,
        'Virtual Network Name', virtual_network_name,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_subnet
    where
      lower(id) = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "network_subnet_route_table" {
  category = category.azure_route_table

  sql = <<-EOQ
    select
      lower(r.id) as id,
      r.title as title,
      jsonb_build_object(
        'Name', r.name,
        'ID', r.id,
        'Type', r.type,
        'Resource Group', r.resource_group,
        'Subscription ID', r.subscription_id
      ) as properties
    from
      azure_route_table as r,
      jsonb_array_elements(r.subnets) as sub
    where
      lower(sub ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "network_subnet_nat_gateway" {
  category = category.azure_nat_gateway

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_nat_gateway,
      jsonb_array_elements(subnets) as s
    where
      lower(s ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}


node "network_subnet_cosmosdb_account" {
  category = category.azure_cosmosdb_account

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "network_subnet_api_management" {
  category = category.azure_api_management

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'ETag', etag,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_api_management
    where
      lower(virtual_network_configuration_subnet_resource_id) = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "network_subnet_application_gateway" {
  category = category.azure_application_gateway

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_application_gateway,
      jsonb_array_elements(gateway_ip_configurations) as c
    where
      lower(c -> 'properties' -> 'subnet' ->> 'id') = any($1)
  EOQ

  param "network_subnet_ids" {}
}

node "network_virtual_network" {
  category = category.azure_virtual_network

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID',  id,
        'Name', name,
        'Etag', etag,
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_virtual_network
    where
      lower(id) = any($1);
  EOQ

  param "virtual_network_ids" {}
}

node "network_virtual_network_route_table" {
  category = category.azure_route_table

  sql = <<-EOQ
    with subnet_list as (
      select
        lower(s ->> 'id') as subnet_id
      from
        azure_virtual_network as v,
        jsonb_array_elements(v.subnets) as s
      where
        lower(v.id) = any($1)
    )
    select
      lower(r.id) as id,
      r.title as title,
      jsonb_build_object(
        'ID', r.id,
        'Name', r.name,
        'Type', r.type,
        'Resource Group', r.resource_group,
        'Subscription ID', r.subscription_id
      ) as properties
    from
      azure_route_table as r,
      jsonb_array_elements(r.subnets) as sub
    where
      lower(sub ->> 'id') in (select subnet_id from subnet_list);
  EOQ

  param "virtual_network_ids" {}
}

node "network_virtual_network_network_peering" {
  category = category.azure_network_peering

  sql = <<-EOQ
    with peering_vn as (
      select
        lower(p -> 'properties' -> 'remoteVirtualNetwork' ->> 'id') as peering_vn
      from
        azure_virtual_network as v,
        jsonb_array_elements(network_peerings) as p
      where
        lower(v.id) = any($1)
    )
    select
      lower(v.id) as id,
      v.title as title,
      jsonb_build_object(
        'ID', id,
        'Name', v.name,
        'Etag', v.etag,
        'Region', v.region,
        'Type', v.type,
        'Resource Group', v.resource_group,
        'Subscription ID', v.subscription_id
      ) as properties
    from
      azure_virtual_network as v
      right join peering_vn as p on lower(p.peering_vn) = lower(v.id);
  EOQ

  param "virtual_network_ids" {}
}

node "network_virtual_network_nat_gateway" {
  category = category.azure_nat_gateway

  sql = <<-EOQ
    with subnet_list as (
      select
        lower(s ->> 'id') as subnet_id
      from
        azure_virtual_network as v,
        jsonb_array_elements(v.subnets) as s
      where
        lower(v.id) = any($1)
    )
    select
      lower(g.id) as id,
      g.title as title,
      jsonb_build_object(
        'ID', g.id,
        'Name', g.name,
        'Type', g.type,
        'Resource Group', g.resource_group,
        'Subscription ID', g.subscription_id
      ) as properties
    from
      azure_nat_gateway as g,
      jsonb_array_elements(g.subnets) as sub
    where
      lower(sub ->> 'id') in (select subnet_id from subnet_list);
  EOQ

  param "virtual_network_ids" {}
}

node "network_virtual_network_application_gateway" {
  category = category.azure_application_gateway

  sql = <<-EOQ
    with subnet_list as (
      select
        lower(s ->> 'id') as subnet_id
      from
        azure_virtual_network as v,
        jsonb_array_elements(v.subnets) as s
      where
        lower(v.id) = any($1)
    )
    select
      lower(g.id) as id,
      g.title as title,
      jsonb_build_object(
        'ID', g.id,
        'Name', g.name,
        'Operational State', g.operational_state,
        'Type', g.type,
        'Resource Group', g.resource_group,
        'Subscription ID', g.subscription_id
      ) as properties
    from
      azure_application_gateway as g,
      jsonb_array_elements(g.gateway_ip_configurations) as ip_config
    where
      lower(ip_config -> 'properties' -> 'subnet' ->> 'id') in (select subnet_id from subnet_list);
  EOQ

  param "virtual_network_ids" {}
}

node "network_virtual_network_backend_address_pool" {
  category = category.azure_lb_backend_address_pool

  sql = <<-EOQ
    with subnet_list as (
      select
        lower(s ->> 'id') as subnet_id
      from
        azure_virtual_network as v,
        jsonb_array_elements(v.subnets) as s
      where
        lower(v.id) = any($1)
    ),
    nic_subnet_list as (
      select
        lower(nic.id) as nic_id,
        lower(ip_config ->> 'id') as ip_config_id,
        ip_config -> 'properties' -> 'subnet' ->> 'id',
        title
      from
        azure_network_interface as nic,
        jsonb_array_elements(ip_configurations) as ip_config
      where
        lower(ip_config -> 'properties' -> 'subnet' ->> 'id') in (select subnet_id from subnet_list)
    )
    select
      lower(p.id) as id,
      p.title as title,
      json_build_object(
        'Name', p.name,
        'Type', p.type,
        'ID', p.id,
        'Resource Group', p.resource_group,
        'Subscription ID', p.subscription_id
      ) as properties
    from
      azure_lb_backend_address_pool as p,
      jsonb_array_elements(p.backend_ip_configurations) as c
    where
      lower(c ->> 'id') in (select ip_config_id from nic_subnet_list);
  EOQ

  param "virtual_network_ids" {}
}
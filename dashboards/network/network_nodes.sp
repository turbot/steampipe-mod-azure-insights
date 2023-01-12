node "network_application_gateway" {
  category = category.network_application_gateway

  sql = <<-EOQ
    select
      lower(g.id) as id,
      g.title as title,
      jsonb_build_object(
        'Name', g.name,
        'ID', lower(g.id),
        'Subscription ID', g.subscription_id,
        'Resource Group', g.resource_group,
        'Region', g.region
      ) as properties
    from
      azure_application_gateway as g
    where
      lower(g.id) = any($1)
  EOQ

  param "network_application_gateway_ids" {}
}

node "network_firewall" {
  category = category.network_firewall

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID',  lower(id),
        'Name', name,
        'Etag', etag,
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_firewall
    where
      lower(id) = any($1);
  EOQ

  param "network_firewall_ids" {}
}

node "network_load_balancer" {
  category = category.network_load_balancer

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID',  lower(id),
        'Name', name,
        'Etag', etag,
        'Type', type,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_lb
    where
      lower(id) = any($1)
  EOQ

  param "network_load_balancer_ids" {}
}

node "network_load_balancer_backend_address_pool" {
  category = category.network_load_balancer_backend_address_pool

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      json_build_object(
        'Name', name,
        'Type', type,
        'ID', lower(id),
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_lb_backend_address_pool
    where
      lower(id) = any($1)
  EOQ

  param "network_load_balancer_backend_address_pool_ids" {}
}

node "network_load_balancer_nat_rule" {
  category = category.network_load_balancer_nat_rule

  sql = <<-EOQ
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
      azure_lb as lb,
      jsonb_array_elements(inbound_nat_rules) as nat_rule
      left join azure_lb_nat_rule as r on lower(r.id) = lower(nat_rule ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}

node "network_load_balancer_probe" {
  category = category.network_load_balancer_probe

  sql = <<-EOQ
    select
      lower(p.id) as id,
      p.title as title,
      jsonb_build_object(
        'ID', p.id,
        'Name', p.name,
        'Type', p.type,
        'Resource Group', p.resource_group,
        'Subscription ID', p.subscription_id
      ) as properties
    from
      azure_lb as lb,
      jsonb_array_elements(probes) as probe
      left join azure_lb_probe as p on lower(p.id) = lower(probe ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}

node "network_load_balancer_rule" {
  category = category.network_load_balancer_rule

  sql = <<-EOQ
    select
      lower(lb_rule.id) as id,
      lb_rule.title as title,
      jsonb_build_object(
        'ID', lb_rule.id,
        'Name', lb_rule.name,
        'Type', lb_rule.type,
        'Resource Group', lb_rule.resource_group,
        'Subscription ID', lb_rule.subscription_id
      ) as properties
    from
      azure_lb as lb,
      jsonb_array_elements(load_balancing_rules) as r
      left join azure_lb_rule as lb_rule on lower(lb_rule.id) = lower(r ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}

node "network_nat_gateway" {
  category = category.network_nat_gateway

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', lower(id),
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_nat_gateway
    where
      lower(id) = any($1)
  EOQ

  param "network_nat_gateway_ids" {}
}

node "network_network_interface" {
  category = category.network_network_interface

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', lower(id),
        'Subscription ID', subscription_id,
        'Resource Group', resource_group,
        'Region', region
      ) as properties
    from
      azure_network_interface
    where
      lower(id) = any($1);
  EOQ

  param "network_network_interface_ids" {}
}

node "network_network_security_group" {
  category = category.network_security_group

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', lower(id),
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_network_security_group
    where
      lower(id) = any($1);
  EOQ

  param "network_network_security_group_ids" {}
}

node "network_public_ip" {
  category = category.network_public_ip

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', lower(id),
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

node "network_route_table" {
  category = category.network_route_table

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', lower(id),
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_route_table
    where
      lower(id) = any($1)
  EOQ

  param "network_route_table_ids" {}
}

node "network_security_group_network_watcher_flow_log" {
  category = category.network_watcher_flow_log

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

  param "network_network_security_group_ids" {}
}

node "network_subnet" {
  category = category.network_subnet

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID' ,lower(id),
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

node "network_virtual_network" {
  category = category.network_virtual_network

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID',  lower(id),
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

  param "network_virtual_network_ids" {}
}

node "network_virtual_network_network_peering" {
  category = category.network_peering

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
        'ID', lower(id),
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

  param "network_virtual_network_ids" {}
}

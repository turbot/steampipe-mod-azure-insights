node "network_network_interface" {
  category = category.network_network_interface

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
  category = category.network_public_ip

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
  category = category.network_security_group

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

  param "network_security_group_ids" {}
}

node "network_subnet" {
  category = category.network_subnet

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
  category = category.network_route_table

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
  category = category.network_nat_gateway

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
  category = category.cosmosdb_account

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
  category = category.api_management

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
  category = category.network_application_gateway

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
  category = category.network_virtual_network

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
  category = category.network_route_table

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
  category = category.network_nat_gateway

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
  category = category.network_application_gateway

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
  category = category.network_load_balancer_backend_address_pool

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

node "network_firewall" {
  category = category.network_firewall

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
      azure_firewall
    where
      lower(id) = any($1);
  EOQ

  param "network_firewall_ids" {}
}

node "network_public_ip_api_management" {
  category = category.api_management

  sql = <<-EOQ
    with public_ip_api_management as (
      select
        id,
        title,
        name,
        provisioning_state,
        subscription_id,
        resource_group,
        region,
        jsonb_array_elements_text(public_ip_addresses) as pid
      from
        azure_api_management
    )
    select
      lower(a.id) as id,
      a.title as title,
      jsonb_build_object(
        'Name', a.name,
        'ID', a.id,
        'Provisioning State', a.provisioning_state,
        'Subscription ID', a.subscription_id,
        'Resource Group', a.resource_group,
        'Region', a.region
      ) as properties
    from
      public_ip_api_management as a
      left join azure_public_ip as p on (a.pid)::inet = p.ip_address
    where
      lower(p.id) = any($1);
  EOQ

  param "network_public_ip_ids" {}
}

node "network_load_balancer" {
  category = category.network_load_balancer

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
      jsonb_array_elements(backend_address_pools) as b
      left join azure_lb_backend_address_pool as p on lower(p.id) = lower(b ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}

node "network_load_balancer_virtual_machine_scale_set_network_interface" {
  category = category.compute_virtual_machine_scale_set_network_interface

  sql = <<-EOQ
    with backend_address_pools as (
      select
        lb.id as lb_id,
        p.id as backend_address_id,
        p.backend_ip_configurations as backend_ip_configurations
      from
        azure_lb as lb,
        jsonb_array_elements(backend_address_pools) as b
        left join azure_lb_backend_address_pool as p on lower(p.id) = lower(b ->> 'id')
      where
        p.backend_ip_configurations is not null
        and lower(lb.id) = any($1)
    ), backend_ip_configurations as (
        select
          lb_id,
          backend_address_id,
          c ->> 'id' as backend_ip_configuration_id
        from
          backend_address_pools,
          jsonb_array_elements(backend_ip_configurations) as c
    )
    select
      lower(nic.id) as id,
      nic.title as title,
      jsonb_build_object(
        'ID', nic.id,
        'Name', nic.name,
        'Type', nic.type,
        'Resource Group', nic.resource_group,
        'Subscription ID', nic.subscription_id
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c,
      backend_ip_configurations as b
    where
      lower(c ->> 'id') = lower(b.backend_ip_configuration_id)
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

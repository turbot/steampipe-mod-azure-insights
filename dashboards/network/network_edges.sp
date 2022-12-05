edge "network_subnet_to_network_virtual_network" {
  title = "virtual network"

  sql = <<-EOQ
    select
      lower(s ->> 'id') as from_id,
      lower(n.id) as to_id
    from
      azure_virtual_network as n,
      jsonb_array_elements(subnets) as s
    where
      lower(s ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_network_interface_to_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    with network_security_group_id as (
      select
        network_security_group_id as sid,
        id as nid
      from
        azure_network_interface
      where
        lower(id) = any($1)
    )
    select
      lower(nsg.id) as to_id,
      lower(nic.nid) as from_id
    from
      azure_network_security_group as nsg
      left join network_security_group_id as nic on lower(nsg.id) = lower(nic.sid)
  EOQ

  param "network_interface_ids" {}
}

edge "network_network_interface_to_network_public_ip" {
  title = "public ip"

  sql = <<-EOQ
    with network_interface_public_ip as (
      select
        id,
        jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
      from
        azure_network_interface
    )
    select
      lower(p.id) as from_id,
      lower(n.id) as to_id
    from
      network_interface_public_ip as n
      left join azure_public_ip as p on lower(p.id) = lower(n.pid)
    where
      lower(n.id) = any($1);
  EOQ

  param "network_interface_ids" {}
}

edge "network_network_interface_to_network_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      lower(s.id) as to_id,
      coalesce(
        lower(ni.network_security_group_id),
        lower(ni.id)
      ) as from_id
    from
      azure_network_interface as ni,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
    where
      lower(ni.id) = any($1);
  EOQ

  param "network_interface_ids" {}
}

edge "network_public_ip_to_api_management" {
  title = "public ip"

  sql = <<-EOQ
   with public_ip_api_management as (
      select
        id,
        title,
        provisioning_state,
        subscription_id,
        resource_group,
        region,
        jsonb_array_elements_text(public_ip_addresses) as pid
      from
        azure_api_management
    )
    select
      lower(a.id) as from_id,
      lower(p.id) as to_id
    from
      public_ip_api_management as a
      left join azure_public_ip as p on (a.pid)::inet = p.ip_address
    where
      lower(p.id) = any($1);
  EOQ

  param "network_public_ip_ids" {}
}

edge "network_security_group_to_network_interface" {
  title = "network interface"

  sql = <<-EOQ
    select
      lower(nsg.id) as from_id,
      lower(nic.id) as to_id
   from
      azure_network_security_group as nsg,
      jsonb_array_elements(network_interfaces) as ni
      left join azure_network_interface as nic on lower(nic.id) = lower(ni ->> 'id')
    where
      lower(nsg.id) = any($1);
  EOQ

  param "network_security_group_ids" {}
}

edge "network_security_group_to_network_watcher_flow_log" {
  title = "nw flow log"

  sql = <<-EOQ
    select
      lower(nsg.id) as from_id,
      lower(fl.id) as to_id
    from
      azure_network_security_group as nsg,
      jsonb_array_elements(flow_logs) as f
      left join azure_network_watcher_flow_log as fl on lower(fl.id) = lower(f->> 'id')
    where
      lower(nsg.id) = any($1);
  EOQ

  param "network_security_group_ids" {}
}

edge "network_security_group_to_compute_virtual_machine" {
  title = "virtual machine"

  sql = <<-EOQ
    with network_interface_list as (
      select
        nsg.id as nsg_id,
        nic.id as nic_id
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(network_interfaces) as ni
        join azure_network_interface as nic on lower(nic.id) = lower(ni ->> 'id')
      where
        lower(nsg.id) = lower($1)
    )
    select
      lower(nic.nsg_id) as from_id,
      lower(vm.id) as to_id
    from
      azure_compute_virtual_machine as vm,
      jsonb_array_elements(network_interfaces) as ni
      join network_interface_list as nic on lower(nic.nic_id) = lower(ni ->> 'id')
  EOQ

  param "network_security_group_ids" {}
}

edge "network_subnet_to_network_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      lower(sub ->> 'id') as from_id,
      lower(r.id) as to_id
    from
      azure_route_table as r,
      jsonb_array_elements(r.subnets) as sub
    where
      lower(sub ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_network_nat_gateway" {
  title = "nat gateway"

  sql = <<-EOQ
    select
      lower(s ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_nat_gateway,
      jsonb_array_elements(subnets) as s
    where
      lower(s ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    select
      lower(sub ->> 'id') as from_id,
      lower(nsg.id) as to_id
    from
      azure_network_security_group as nsg,
      jsonb_array_elements(nsg.subnets) as sub
    where
      lower(sub ->> 'id') = any($1)
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_app_service_web_app" {
  title = "web app"

  sql = <<-EOQ
    select
      lower(vnet_connection -> 'properties' ->> 'vnetResourceId') as from_id,
      id as to_id
    from
      azure_app_service_web_app
    where
      lower(vnet_connection -> 'properties' ->> 'vnetResourceId') = any($1)
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_sql_server" {
  title = "sql server"

  sql = <<-EOQ
    select
      lower(r -> 'properties' ->> 'virtualNetworkSubnetId') as from_id,
      lower(id) as to_id
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r -> 'properties' ->> 'virtualNetworkSubnetId') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(r ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_storage_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_cosmosdb_account" {
  title = "cosmosdb"

  sql = <<-EOQ
    select
      lower(r ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_api_management" {
  title = "api management"

  sql = <<-EOQ
    select
      lower(virtual_network_configuration_subnet_resource_id) as from_id,
      lower(id) as to_id
    from
      azure_api_management
    where
      lower(virtual_network_configuration_subnet_resource_id) = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_network_application_gateway" {
  title = "application gateway"

  sql = <<-EOQ
    select
      lower(c -> 'properties' -> 'subnet' ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_application_gateway,
      jsonb_array_elements(gateway_ip_configurations) as c
    where
      lower(c -> 'properties' -> 'subnet' ->> 'id') = any($1)
  EOQ

  param "network_subnet_ids" {}
}

edge "network_virtual_network_to_network_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      lower(v.id) as from_id,
      lower(sub.id) as to_id
    from
      azure_virtual_network as v,
      jsonb_array_elements(subnets) as s
      left join azure_subnet as sub on lower(sub.id) = lower(s ->> 'id')
    where
      lower(v.id) = any($1);
  EOQ

  param "virtual_network_ids" {}
}

edge "network_virtual_network_to_network_peering" {
  title = "network peering"

  sql = <<-EOQ
    with peering_vn as (
      select
        v.id as network_id
        p -> 'properties' -> 'remoteVirtualNetwork' ->> 'id' as peering_vn
      from
        azure_virtual_network as v,
        jsonb_array_elements(network_peerings) as p
      where
        v.id = any($1)
    )
    select
      p.network_id as from_id,
      p.peering_vn as to_id
    from
      azure_virtual_network as v
      right join peering_vn as p on p.peering_vn = v.id;
  EOQ

  param "virtual_network_ids" {}
}

edge "network_virtual_network_to_compute_virtual_machine" {
  title = "virtual machine"

  sql = <<-EOQ
    with subnet_list as (
      select
        id as vn_id,
        lower(sub ->> 'id') as sub_id,
        sub ->> 'name' as sub_name
      from
        azure_virtual_network as n,
        jsonb_array_elements(subnets) as sub
      where
        lower(id) = any($1)
    ),
    virtual_machine_nic_list as (
      select
        m.id as machine_id,
        n.ip_configurations as ip_configs
      from
        azure_compute_virtual_machine as m,
        jsonb_array_elements(network_interfaces) as nic
        left join azure_network_interface as n on lower(n.id) = lower(nic ->> 'id')
    )
    select
      lower(ip_config -> 'properties' -> 'subnet' ->> 'id') as from_id,
      lower(l.machine_id) as to_id
    from
      virtual_machine_nic_list as l,
      jsonb_array_elements(ip_configs) as ip_config
    where
      lower(ip_config -> 'properties' -> 'subnet' ->> 'id') in (select sub_id from subnet_list);
  EOQ

  param "virtual_network_ids" {}
}

edge "network_virtual_network_to_backend_address_pool" {
  title = "lb backend address pool"

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
        lower(ip_config -> 'properties' -> 'subnet' ->> 'id') as subnet_id,
        title
      from
        azure_network_interface as nic,
        jsonb_array_elements(ip_configurations) as ip_config
      where
        lower(ip_config -> 'properties' -> 'subnet' ->> 'id') in (select subnet_id from subnet_list)
    )
    select
      s.subnet_id as from_id,
      lower(p.id) as to_id
    from
      azure_lb_backend_address_pool as p,
      jsonb_array_elements(p.backend_ip_configurations) as c
      left join nic_subnet_list as s on s.ip_config_id = lower(c ->> 'id')
    where
      lower(c ->> 'id') in (select ip_config_id from nic_subnet_list);
  EOQ

  param "virtual_network_ids" {}
}

edge "network_virtual_network_to_network_load_balancer" {
  title = "lb"

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
    ),
    azure_lb_backend_address_pool as (
      select
        lower(p.id) as pool_id,
        lower(c ->> 'id')
      from
        azure_lb_backend_address_pool as p,
        jsonb_array_elements(p.backend_ip_configurations) as c
      where
        lower(c ->> 'id') in (select ip_config_id from nic_subnet_list)
    )
    select
      lower(pool ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_lb,
      jsonb_array_elements(backend_address_pools) as pool
    where
      lower(pool ->> 'id') in (select pool_id from azure_lb_backend_address_pool);
  EOQ

  param "virtual_network_ids" {}
}
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
      lower(id) as to_id
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

edge "network_firewall_to_public_ip" {
  title = "public ip"

  sql = <<-EOQ
    select
      lower(f.id) as from_id,
      lower(ip.id) as to_id
    from
      azure_firewall as f,
      jsonb_array_elements(ip_configurations) as c
      left join azure_public_ip as ip on lower(ip.id) = lower(c -> 'publicIPAddress' ->> 'id')
    where
      lower(f.id) = any($1);
  EOQ

  param "network_firewall_ids" {}
}

edge "network_firewall_to_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      lower(f.id) as from_id,
      lower(s.id) as to_id
    from
      azure_firewall as f,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'subnet' ->> 'id')
    where
      lower(f.id) = any($1);
  EOQ

  param "network_firewall_ids" {}
}

edge "network_load_balancer_to_backend_address_pool" {
  title = "backend address pool"

  sql = <<-EOQ
    select
      lower(lb.id) as from_id,
      lower(p.id) as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as b
      left join azure_lb_backend_address_pool as p on lower(p.id) = lower(b ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}

edge "network_load_balancer_to_load_balancer_rule" {
  title = "lb rule"

  sql = <<-EOQ
    select
      lower(lb.id) as from_id,
      lower(lb_rule.id) as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(load_balancing_rules) as r
      left join azure_lb_rule as lb_rule on lower(lb_rule.id) = lower(r ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}

edge "network_load_balancer_to_lb_probe" {
  title = "probe"

  sql = <<-EOQ
    select
      lower(lb.id) as from_id,
      lower(p.id) as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(probes) as probe
      left join azure_lb_probe as p on lower(p.id) = lower(probe ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}

edge "network_load_balancer_to_lb_nat_rule" {
  title = "nat rule"

  sql = <<-EOQ
    select
      lower(lb.id) as from_id,
      lower(r.id) as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(inbound_nat_rules) as nat_rule
      left join azure_lb_nat_rule as r on lower(r.id) = lower(nat_rule ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}

edge "network_backend_address_pool_to_network_interface_edge" {
  title = "network interface"

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
      lower(b.backend_address_id) as from_id,
      lower(nic.id) as to_id
    from
      azure_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c,
      backend_ip_configurations as b
    where
      lower(c ->> 'id') = lower(b.backend_ip_configuration_id)
    union
    select
      lower(b.backend_address_id) as from_id,
      lower(nic.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c,
      backend_ip_configurations as b
    where
      lower(c ->> 'id') = lower(b.backend_ip_configuration_id)
  EOQ

  param "network_load_balancer_ids" {}
}

edge "network_network_interface_to_compute_virtual_machine" {
  title = "virtual machine"

  sql = <<-EOQ
    with backend_address_pools as (
      select
        lower(lb.id) as lb_id,
        lower(p.id) as backend_address_id,
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
          lower(c ->> 'id') as backend_ip_configuration_id
        from
          backend_address_pools,
          jsonb_array_elements(backend_ip_configurations) as c
    ), network_interface as (
        select
          lb_id,
          backend_address_id,
          nic.id as nic_id,
          nic.virtual_machine_id as virtual_machine_id,
          c ->> 'id' as backend_ip_configuration_id
        from
          azure_network_interface as nic,
          jsonb_array_elements(ip_configurations) as c,
          backend_ip_configurations as b
        where
          lower(c ->> 'id') = b.backend_ip_configuration_id
    )
    select
      lower(nic.nic_id) as from_id,
      lower(vm.id) as to_id
    from
      azure_compute_virtual_machine as vm
      left join network_interface as nic on lower(nic.virtual_machine_id) = lower(vm.id)
  EOQ

  param "network_load_balancer_ids" {}
}

edge "network_network_interface_to_compute_scale_set_vm" {
  title = "scale set vm"

  sql = <<-EOQ
    with backend_address_pools as (
      select
        lower(lb.id) as lb_id,
        lower(p.id) as backend_address_id,
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
          lower(c ->> 'id') as backend_ip_configuration_id
        from
          backend_address_pools,
          jsonb_array_elements(backend_ip_configurations) as c
    ), network_interface as (
        select
          lb_id,
          backend_address_id,
          nic.id as nic_id,
          nic.virtual_machine ->> 'id' as virtual_machine_id,
          c ->> 'id' as backend_ip_configuration_id
        from
          azure_compute_virtual_machine_scale_set_network_interface as nic,
          jsonb_array_elements(ip_configurations) as c,
          backend_ip_configurations as b
        where
          lower(c ->> 'id') = b.backend_ip_configuration_id
    )
    select
      lower(nic.nic_id) as from_id,
      lower(vm.id) as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      right join network_interface as nic on lower(nic.virtual_machine_id) = lower(vm.id)
  EOQ

  param "network_load_balancer_ids" {}
}

edge "network_backend_address_pool_to_virtual_network" {
  title = "virtual network"

  sql = <<-EOQ
    with backend_address_pools as (
      select
        lb.id as lb_id,
        p.id as backend_address_id,
        p.load_balancer_backend_addresses as load_balancer_backend_addresses
      from
        azure_lb as lb,
        jsonb_array_elements(backend_address_pools) as b
        left join azure_lb_backend_address_pool as p on lower(p.id) = lower(b ->> 'id')
      where
        p.load_balancer_backend_addresses is not null
        and lower(lb.id) = any($1)
    ),load_balancer_backend_addresses_list as (
        select
          lb_id,
          backend_address_id,
          a -> 'properties' -> 'virtualNetwork' ->> 'id' as vn_id
        from
          backend_address_pools,
          jsonb_array_elements(load_balancer_backend_addresses) as a
        where
          a -> 'properties' -> 'virtualNetwork' ->> 'id' is not null
    )
    select
      lower(b.backend_address_id) as from_id,
      lower(vn.id) as to_id
    from
      azure_virtual_network as vn
      right join load_balancer_backend_addresses_list as b on lower(b.vn_id) = lower(vn.id)
  EOQ

  param "network_load_balancer_ids" {}
}


edge "network_load_balancer_from_virtual_machine_scale_set" {
  title = "load balancer"

  sql = <<-EOQ
    select
      lower(vm_scale_set.id) as from_id,
      lower(split_part( b ->> 'id', '/backendAddressPools' , 1)) as to_id
    from
      azure_compute_virtual_machine_scale_set as vm_scale_set,
      jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as p,
      jsonb_array_elements(p -> 'properties' -> 'ipConfigurations') as c,
      jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools') as b
    where
      lower(split_part( b ->> 'id', '/backendAddressPools' , 1)) = any($1)
  EOQ

  param "network_load_balancer_ids" {}
}

edge "network_load_balancer_to_network_public_ip" {
  title = "frontend public ip"

  sql = <<-EOQ
    select
      lower(lb.id) as from_id,
      lower(ip.id) as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(frontend_ip_configurations) as f
      left join azure_public_ip as ip on lower(ip.id) = lower(f -> 'properties' -> 'publicIPAddress' ->> 'id')
    where
      lower(lb.id) = any($1);
  EOQ

  param "network_load_balancer_ids" {}
}
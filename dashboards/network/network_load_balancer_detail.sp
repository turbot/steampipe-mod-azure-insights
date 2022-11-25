dashboard "azure_network_load_balancer_detail" {

  title         = "Azure Network Load Balancer Detail"
  documentation = file("./dashboards/network/docs/network_load_balancer_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "lb_id" {
    title = "Select a load balancer:"
    query = query.azure_network_load_balancer_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_network_load_balancer_sku_name
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_load_balancer_sku_tier
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_load_balancer_backend_pool_count
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_load_balancer_rules_count
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_load_nat_rules_count
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_load_probes_count
      args = {
        id = self.input.lb_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azure_load_balancer_node,
        node.azure_load_balancer_to_backend_address_pool_node,
        node.azure_load_balancer_backend_address_pool_to_network_interface_node,
        node.azure_load_balancer_backend_address_pool_to_virtual_machine_scale_set_network_interface_node,
        node.azure_load_balancer_backend_address_pool_network_interface_to_compute_virtual_machine_node,
        node.azure_load_balancer_backend_address_pool_network_interface_to_compute_scale_set_vm_node,
        node.azure_load_balancer_backend_address_pool_to_virtual_network_node,
        node.azure_load_balancer_to_load_balancer_rule_node,
        node.azure_load_balancer_to_lb_probe_node,
        node.azure_load_balancer_to_lb_nat_rule_node,
        node.azure_load_balancer_from_virtual_machine_scale_set_node,
        node.azure_load_balancer_to_public_ip_node
      ]

      edges = [
        edge.azure_load_balancer_to_backend_address_pool_edge,
        edge.azure_load_balancer_backend_address_pool_to_network_interface_edge,
        edge.azure_load_balancer_backend_address_pool_network_interface_to_compute_virtual_machine_edge,
        edge.azure_load_balancer_backend_address_pool_network_interface_to_compute_scale_set_vm_edge,
        edge.azure_load_balancer_backend_address_pool_to_virtual_network_edge,
        edge.azure_load_balancer_to_load_balancer_rule_edge,
        edge.azure_load_balancer_to_lb_probe_edge,
        edge.azure_load_balancer_to_lb_nat_rule_edge,
        edge.azure_load_balancer_from_virtual_machine_scale_set_edge,
        edge.azure_load_balancer_to_public_ip_edge
      ]

      args = {
        id = self.input.lb_id.value
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.azure_network_load_balancer_overview
        args = {
          id = self.input.lb_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_network_load_balancer_tags
        args = {
          id = self.input.lb_id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Associated Virtual Machine Scale Sets"
        query = query.azure_load_balancer_associated_virtual_machine_scale_sets
        args = {
          id = self.input.lb_id.value
        }

        column "Name" {
          href = "${dashboard.azure_compute_virtual_machine_scale_set_detail.url_path}?input.vm_scale_set_id={{.'Scale Set ID' | @uri}}"
        }
      }

      table {
        title = "Backend Pools"
        query = query.azure_load_balancer_backend_pools
        args = {
          id = self.input.lb_id.value
        }
      }

    }

  }

  container {

    table {
      title = "Frontend IP Configurations"
      query = query.azure_load_balancer_frontend_ip_configurations
      args = {
        id = self.input.lb_id.value
      }
    }
  }

  container {

    table {
      title = "Probes"
      query = query.azure_load_balancer_probe
      args = {
        id = self.input.lb_id.value
      }
    }
  }

  container {

    table {
      title = "Inbound NAT Rules"
      query = query.azure_load_balancer_inbound_nat_rules
      args = {
        id = self.input.lb_id.value
      }
    }

  }

  container {

    table {
      title = "Outbound Rules"
      query = query.azure_load_balancer_outbound_rules
      args = {
        id = self.input.lb_id.value
      }
    }

  }

  container {

    table {
      title = "Load Balancing Rules"
      query = query.azure_load_balancer_load_balancing_rules
      args = {
        id = self.input.lb_id.value
      }
    }
  }

}

query "azure_network_load_balancer_input" {
  sql = <<-EOQ
    select
      lb.title as label,
      lb.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', lb.resource_group,
        'region', lb.region
      ) as tags
    from
      azure_lb as lb,
      azure_subscription as s
    where
      lower(lb.subscription_id) = lower(s.subscription_id)
    order by
      lb.title;
  EOQ
}

query "azure_network_load_balancer_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_lb
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_load_balancer_sku_tier" {
  sql = <<-EOQ
    select
      'SKU Tier' as label,
      sku_tier as value
    from
      azure_lb
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_load_balancer_backend_pool_count" {
  sql = <<-EOQ
    select
      'Backend Address Pools' as label,
      jsonb_array_length(backend_address_pools) as value
    from
      azure_lb
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_load_balancer_rules_count" {
  sql = <<-EOQ
    select
      'Load balancing Rules' as label,
      jsonb_array_length(load_balancing_rules) as value
    from
      azure_lb
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_load_nat_rules_count" {
  sql = <<-EOQ
    select
      'Inbound NAT Rules' as label,
      jsonb_array_length(inbound_nat_rules) as value
    from
      azure_lb
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_load_probes_count" {
  sql = <<-EOQ
    select
      'Probes' as label,
      jsonb_array_length(probes) as value
    from
      azure_lb
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_load_balancer_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      etag as "Etag",
      provisioning_state as "Provisioning State",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_lb
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_load_balancer_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_lb,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_load_balancer_associated_virtual_machine_scale_sets" {
  sql = <<-EOQ
    select
      vm_scale_set.name as "Name",
      vm_scale_set.id as "ID",
      vm_scale_set.sku_name as "SKU Name",
      vm_scale_set.sku_tier as "SKU Tier",
      vm_scale_set.id as "Scale Set ID"
    from
      azure_compute_virtual_machine_scale_set as vm_scale_set,
      jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as p,
      jsonb_array_elements(p -> 'properties' -> 'ipConfigurations') as c,
      jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools') as b
    where
      split_part( b ->> 'id', '/backendAddressPools' , 1) = $1
    EOQ

  param "id" {}
}

query "azure_load_balancer_backend_pools" {
  sql = <<-EOQ
    select
      p ->> 'name' as "Name",
      p ->> 'id' as "ID"
    from
      azure_lb,
      jsonb_array_elements(backend_address_pools) as p
    where
      id = $1;
    EOQ

  param "id" {}
}

query "azure_load_balancer_frontend_ip_configurations" {
  sql = <<-EOQ
    select
      c ->> 'name' as "Name",
      c -> 'properties' ->> 'privateIPAllocationMethod' as "Private IP Allocation Method",
      c -> 'properties' -> 'publicIPAddress'->> 'id' as "Public IP Address ID",
      c ->> 'id' as "ID"
    from
      azure_lb,
      jsonb_array_elements(frontend_ip_configurations) as c
    where
      id = $1;
    EOQ

  param "id" {}
}

query "azure_load_balancer_probe" {
  sql = <<-EOQ
    select
      p ->> 'name' as "Name",
      p -> 'properties' ->> 'intervalInSeconds' as "Interval In Seconds",
      p -> 'properties' ->> 'numberOfProbes' as "Number Of Probes",
      p -> 'properties' ->> 'port' as "Port",
      p -> 'properties' ->> 'protocol' as "Protocol",
      p ->> 'id' as "ID"
    from
      azure_lb,
      jsonb_array_elements(probes) as p
    where
      id = $1;
    EOQ

  param "id" {}
}

query "azure_load_balancer_inbound_nat_rules" {
  sql = <<-EOQ
    select
      p ->> 'name' as "Name",
      p -> 'properties' ->> 'backendPort' as "Backend Port",
      p -> 'properties' ->> 'enableFloatingIP' as "Enable Floating IP",
      p -> 'properties' ->> 'enableTcpReset' as "Enable TCP Reset",
      p -> 'properties' -> 'frontendIPConfiguration' ->> 'id' as "Frontend IP Configuration ID",
      p -> 'properties' ->> 'frontendPort' as "Frontend Port",
      p -> 'properties' ->> 'idleTimeoutInMinutes' as "Idle Timeout In Minutes",
      p -> 'properties' ->> 'protocol' as "Protocol",
      p ->> 'id' as "ID"
    from
      azure_lb,
      jsonb_array_elements(inbound_nat_rules) as p
    where
      id = $1;
    EOQ

  param "id" {}
}

query "azure_load_balancer_outbound_rules" {
  sql = <<-EOQ
    select
      r ->> 'name' as "Name",
      r -> 'properties' ->> 'allocatedOutboundPorts' as "Allocated Outbound Ports",
      r -> 'properties' ->> 'enableTcpReset' as "Enable TCP Reset",
      r -> 'properties' ->> 'frontendPort' as "Frontend Port",
      r -> 'properties' ->> 'idleTimeoutInMinutes' as "Idle Timeout In Minutes",
      r -> 'properties' ->> 'protocol' as "Protocol",
      r -> 'properties' -> 'frontendIPConfigurations' ->> 'id' as "Frontend IP Configuration ID",
      r -> 'properties' -> 'backendAddressPool'  ->> 'id' as "Backend Address Pool ID",
      r ->> 'id' as "ID"
    from
      azure_lb,
      jsonb_array_elements(outbound_rules) as r
    where
      id = $1;
    EOQ

  param "id" {}
}

query "azure_load_balancer_load_balancing_rules" {
  sql = <<-EOQ
    select
      r ->> 'name' as "Name",
      r -> 'properties' ->> 'backendPort' as "Backend Port",
      r -> 'properties' ->> 'disableOutboundSnat' as "Disable Outbound Snat",
      r -> 'properties' ->> 'enableFloatingIP' as "Enable Floating IP",
      r -> 'properties' ->> 'enableTcpReset' as "Enable TCP Reset",
      r -> 'properties' -> 'frontendPort' as "Frontend Port",
      r -> 'properties' -> 'idleTimeoutInMinutes' as "Idle Timeout In Minutes",
      r -> 'properties' -> 'backendAddressPool' ->> 'id' as "Backend Address Pool",
      r -> 'properties' -> 'frontendIPConfiguration' ->> 'id' as "Frontend IP Configuration ID",
      r -> 'properties' -> 'probe' ->> 'id' as "Probe ID",
      r -> 'properties' ->> 'protocol'  as "Protocol",
      r ->> 'id' as "ID"
    from
      azure_lb,
      jsonb_array_elements(load_balancing_rules) as r
    where
      id = $1;
    EOQ

  param "id" {}
}

node "azure_load_balancer_node" {
  category = category.azure_lb

  sql = <<-EOQ
    select
      id as id,
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
      id = $1;
  EOQ

  param "id" {}
}

node "azure_load_balancer_to_backend_address_pool_node" {
  category = category.azure_lb_backend_address_pool

  sql = <<-EOQ
    select
      p.id as id,
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
      lb.id = $1;
  EOQ

  param "id" {}
}

edge "azure_load_balancer_to_backend_address_pool_edge" {
  title = "backend address pool"

  sql = <<-EOQ
    select
      lb.id as from_id,
      p.id as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(backend_address_pools) as b
      left join azure_lb_backend_address_pool as p on lower(p.id) = lower(b ->> 'id')
    where
      lb.id = $1;
  EOQ

  param "id" {}
}

node "azure_load_balancer_backend_address_pool_to_network_interface_node" {
  category = category.azure_network_interface

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
        and lower(lb.id) = lower($1)
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
      nic.id as id,
      nic.title as title,
      jsonb_build_object(
        'ID', nic.id,
        'Name', nic.name,
        'Type', nic.type,
        'Resource Group', nic.resource_group,
        'Subscription ID', nic.subscription_id
      ) as properties
    from
      azure_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c,
      backend_ip_configurations as b
    where
      lower(c ->> 'id') = lower(b.backend_ip_configuration_id)
  EOQ

  param "id" {}
}

node "azure_load_balancer_backend_address_pool_to_virtual_machine_scale_set_network_interface_node" {
  category = category.azure_compute_virtual_machine_scale_set_network_interface

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
        and lower(lb.id) = lower($1)
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
      nic.id as id,
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

  param "id" {}
}


edge "azure_load_balancer_backend_address_pool_to_network_interface_edge" {
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
        and lower(lb.id) = lower($1)
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
      b.backend_address_id as from_id,
      nic.id as to_id
    from
      azure_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c,
      backend_ip_configurations as b
    where
      lower(c ->> 'id') = lower(b.backend_ip_configuration_id)
    union
    select
      b.backend_address_id as from_id,
      nic.id as to_id
    from
      azure_compute_virtual_machine_scale_set_network_interface as nic,
      jsonb_array_elements(ip_configurations) as c,
      backend_ip_configurations as b
    where
      lower(c ->> 'id') = lower(b.backend_ip_configuration_id)
  EOQ

  param "id" {}
}

node "azure_load_balancer_backend_address_pool_to_virtual_network_node" {
  category = category.azure_virtual_network

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
        and lb.id = $1
    ),load_balancer_backend_addresses_list as (
        select
          lb_id,
          a -> 'properties' -> 'virtualNetwork' ->> 'id' as vn_id
        from
          backend_address_pools,
          jsonb_array_elements(load_balancer_backend_addresses) as a
        where
          a -> 'properties' -> 'virtualNetwork' ->> 'id' is not null
    )
    select
      vn.id as id,
      vn.title as title,
      jsonb_build_object(
        'ID', vn.id,
        'Name', vn.name,
        'Type', vn.type,
        'Resource Group', vn.resource_group,
        'Subscription ID', vn.subscription_id
      ) as properties
    from
      azure_virtual_network as vn
      right join load_balancer_backend_addresses_list as b on lower(b.vn_id) = lower(vn.id)
  EOQ

  param "id" {}
}

edge "azure_load_balancer_backend_address_pool_to_virtual_network_edge" {
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
        and lb.id = $1
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
      b.backend_address_id as from_id,
      vn.id as to_id
    from
      azure_virtual_network as vn
      right join load_balancer_backend_addresses_list as b on lower(b.vn_id) = lower(vn.id)
  EOQ

  param "id" {}
}

node "azure_load_balancer_backend_address_pool_network_interface_to_compute_virtual_machine_node" {
  category = category.azure_compute_virtual_machine

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
        and lb.id = $1
    ), backend_ip_configurations as (
        select
          lb_id,
          backend_address_id,
          c ->> 'id' as backend_ip_configuration_id
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
          c ->> 'id' = b.backend_ip_configuration_id
    )
    select
      vm.id as id,
      vm.title as title,
      jsonb_build_object(
        'ID', vm.id,
        'Name', vm.name,
        'Type', vm.type,
        'Resource Group', vm.resource_group,
        'Subscription ID', vm.subscription_id
      ) as properties
    from
      azure_compute_virtual_machine as vm
      right join network_interface as nic on lower(nic.virtual_machine_id) = lower(vm.id)
  EOQ

  param "id" {}
}

edge "azure_load_balancer_backend_address_pool_network_interface_to_compute_virtual_machine_edge" {
  title = "virtual machine"

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
        and lb.id = $1
    ), backend_ip_configurations as (
        select
          lb_id,
          backend_address_id,
          c ->> 'id' as backend_ip_configuration_id
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
          c ->> 'id' = b.backend_ip_configuration_id
    )
    select
      nic.nic_id as from_id,
      vm.id as to_id
    from
      azure_compute_virtual_machine as vm
      right join network_interface as nic on lower(nic.virtual_machine_id) = lower(vm.id)
  EOQ

  param "id" {}
}

node "azure_load_balancer_backend_address_pool_network_interface_to_compute_scale_set_vm_node" {
  category = category.azure_compute_virtual_machine_scale_set_vm

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
        and lb.id = $1
    ), backend_ip_configurations as (
        select
          lb_id,
          backend_address_id,
          c ->> 'id' as backend_ip_configuration_id
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
          c ->> 'id' = b.backend_ip_configuration_id
    )
    select
      vm.id as id,
      vm.title as title,
      jsonb_build_object(
        'ID', vm.id,
        'Name', vm.name,
        'Type', vm.type,
        'Resource Group', vm.resource_group,
        'Subscription ID', vm.subscription_id
      ) as properties
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      right join network_interface as nic on lower(nic.virtual_machine_id) = lower(vm.id)
  EOQ

  param "id" {}
}

edge "azure_load_balancer_backend_address_pool_network_interface_to_compute_scale_set_vm_edge" {
  title = "scale set vm"

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
        and lb.id = $1
    ), backend_ip_configurations as (
        select
          lb_id,
          backend_address_id,
          c ->> 'id' as backend_ip_configuration_id
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
          c ->> 'id' = b.backend_ip_configuration_id
    )
    select
      nic.nic_id as from_id,
      vm.id as to_id
    from
      azure_compute_virtual_machine_scale_set_vm as vm
      right join network_interface as nic on lower(nic.virtual_machine_id) = lower(vm.id)
  EOQ

  param "id" {}
}

node "azure_load_balancer_to_load_balancer_rule_node" {
  category = category.azure_lb_rule

  sql = <<-EOQ
    select
      lb_rule.id as id,
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
      lb.id = $1;
  EOQ

  param "id" {}
}

edge "azure_load_balancer_to_load_balancer_rule_edge" {
  title = "lb rule"

  sql = <<-EOQ
    select
      lb.id as from_id,
      lb_rule.id as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(load_balancing_rules) as r
      left join azure_lb_rule as lb_rule on lower(lb_rule.id) = lower(r ->> 'id')
    where
      lb.id = $1;
  EOQ

  param "id" {}
}

node "azure_load_balancer_to_lb_probe_node" {
  category = category.azure_lb_probe

  sql = <<-EOQ
    select
      p.id as id,
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
      lb.id = $1;
  EOQ

  param "id" {}
}

edge "azure_load_balancer_to_lb_probe_edge" {
  title = "probe"

  sql = <<-EOQ
    select
      lb.id as from_id,
      p.id as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(probes) as probe
      left join azure_lb_probe as p on lower(p.id) = lower(probe ->> 'id')
    where
      lb.id = $1;
  EOQ

  param "id" {}
}

node "azure_load_balancer_to_lb_nat_rule_node" {
  category = category.azure_lb_nat_rule

  sql = <<-EOQ
    select
      r.id as id,
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
      lb.id = $1;
  EOQ

  param "id" {}
}

edge "azure_load_balancer_to_lb_nat_rule_edge" {
  title = "nat rule"

  sql = <<-EOQ
    select
      lb.id as from_id,
      r.id as to_id
    from
      azure_lb as lb,
      jsonb_array_elements(inbound_nat_rules) as nat_rule
      left join azure_lb_nat_rule as r on lower(r.id) = lower(nat_rule ->> 'id')
    where
      lb.id = $1;
  EOQ

  param "id" {}
}

node "azure_load_balancer_from_virtual_machine_scale_set_node" {
  category = category.azure_compute_virtual_machine_scale_set

  sql = <<-EOQ
    select
      vm_scale_set.id as id,
      vm_scale_set.title as title,
      jsonb_build_object(
        'ID', vm_scale_set.id,
        'Name', vm_scale_set.name,
        'Type', vm_scale_set.type,
        'Resource Group', vm_scale_set.resource_group,
        'Subscription ID', vm_scale_set.subscription_id
      ) as properties
    from
      azure_compute_virtual_machine_scale_set as vm_scale_set,
      jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as p,
      jsonb_array_elements(p -> 'properties' -> 'ipConfigurations') as c,
      jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools') as b
    where
      split_part( b ->> 'id', '/backendAddressPools' , 1) = $1
  EOQ

  param "id" {}
}

edge "azure_load_balancer_from_virtual_machine_scale_set_edge" {
  title = "load balancer"

  sql = <<-EOQ
    select
      vm_scale_set.id as from_id,
      $1 as to_id
    from
      azure_compute_virtual_machine_scale_set as vm_scale_set,
      jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as p,
      jsonb_array_elements(p -> 'properties' -> 'ipConfigurations') as c,
      jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools') as b
    where
      split_part( b ->> 'id', '/backendAddressPools' , 1) = $1
  EOQ

  param "id" {}
}

node "azure_load_balancer_to_public_ip_node" {
  category = category.azure_public_ip

  sql = <<-EOQ
    select
      ip.id as id,
      ip.title as title,
      jsonb_build_object(
        'ID', ip.id,
        'Name', ip.name,
        'Type', ip.type,
        'Resource Group', ip.resource_group,
        'Subscription ID', ip.subscription_id
      ) as properties
    from
      azure_lb as lb,
      jsonb_array_elements(frontend_ip_configurations) as f
      left join azure_public_ip as ip on lower(ip.id) = lower(f -> 'properties' -> 'publicIPAddress' ->> 'id')
    where
      lb.id = $1;
  EOQ

  param "id" {}
}

edge "azure_load_balancer_to_public_ip_edge" {
  title = "frontend public ip"

  sql = <<-EOQ
    select
      lb.id as from_id,
      ip.id as to_id,
      jsonb_build_object(
        'Frontend IP Configuration ID', f -> 'id',
        'Frontend IP Configuration Name', f -> 'name',
        'Private IP Allocation Method', f -> 'properties' -> 'privateIPAllocationMethod',
        'Resource Group', lb.resource_group,
        'Subscription ID', lb.subscription_id
      ) as properties
    from
      azure_lb as lb,
      jsonb_array_elements(frontend_ip_configurations) as f
      left join azure_public_ip as ip on lower(ip.id) = lower(f -> 'properties' -> 'publicIPAddress' ->> 'id')
    where
      lb.id = $1;;
  EOQ

  param "id" {}
}


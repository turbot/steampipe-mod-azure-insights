dashboard "network_load_balancer_detail" {

  title         = "Azure Network Load Balancer Detail"
  documentation = file("./dashboards/network/docs/network_load_balancer_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "lb_id" {
    title = "Select a load balancer:"
    query = query.network_load_balancer_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.network_load_balancer_sku_name
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.network_load_balancer_sku_tier
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.network_load_balancer_backend_pool_count
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.network_load_balancer_rules_count
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.network_load_nat_rules_count
      args = {
        id = self.input.lb_id.value
      }
    }

    card {
      width = 2
      query = query.network_load_probes_count
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

      with "compute_virtual_machine_scale_set_vms" {
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
              and lower(lb.id) = $1
          ),
          backend_ip_configurations as (
            select
              lb_id,
              backend_address_id,
              c ->> 'id' as backend_ip_configuration_id
            from
              backend_address_pools,
              jsonb_array_elements(backend_ip_configurations) as c
          ),
          network_interface as (
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
              lower(c ->> 'id') = lower(b.backend_ip_configuration_id)
          )
        select
          lower(id) as virtual_machine_scale_set_vm_id
        from
          azure_compute_virtual_machine_scale_set_vm as vm
        where
          lower(id) in (select lower(virtual_machine_id) from network_interface )
        EOQ

        args = [self.input.lb_id.value]
      }

      with "compute_virtual_machine_scale_sets" {
        sql = <<-EOQ
          select
            lower(vm_scale_set.id) as compute_virtual_machine_scale_set_id
          from
            azure_compute_virtual_machine_scale_set as vm_scale_set,
            jsonb_array_elements(virtual_machine_network_profile -> 'networkInterfaceConfigurations') as p,
            jsonb_array_elements(p -> 'properties' -> 'ipConfigurations') as c,
            jsonb_array_elements(c -> 'properties' -> 'loadBalancerBackendAddressPools') as b
          where
            lower(split_part( b ->> 'id', '/backendAddressPools' , 1)) = $1
        EOQ

        args = [self.input.lb_id.value]
      }

      with "compute_virtual_machines" {
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
              and lower(lb.id) = $1
          ),
          backend_ip_configurations as (
            select
              lb_id,
              backend_address_id,
              c ->> 'id' as backend_ip_configuration_id
            from
              backend_address_pools,
              jsonb_array_elements(backend_ip_configurations) as c
          ),
          network_interface as (
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
            lower(id) as virtual_machine_id
          from
            azure_compute_virtual_machine
          where
            lower(id) in (select lower(virtual_machine_id) from network_interface)
        EOQ

        args = [self.input.lb_id.value]
      }

      with "network_load_balancer_backend_address_pools" {
        sql = <<-EOQ
          select
            lower(p.id) as pool_id
          from
            azure_lb as lb,
            jsonb_array_elements(backend_address_pools) as b
            left join azure_lb_backend_address_pool as p on lower(p.id) = lower(b ->> 'id')
          where
            lower(lb.id) = $1;
        EOQ

        args = [self.input.lb_id.value]
      }

      with "network_network_interfaces" {
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
              and lower(lb.id) = $1
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
            lower(nic.id) as network_interface_id
          from
            azure_network_interface as nic,
            jsonb_array_elements(ip_configurations) as c,
            backend_ip_configurations as b
          where
            lower(c ->> 'id') = lower(b.backend_ip_configuration_id)
          EOQ

        args = [self.input.lb_id.value]
      }

      with "network_public_ips" {
        sql = <<-EOQ
          select
            lower(ip.id) as public_ip_id
          from
            azure_lb as lb,
            jsonb_array_elements(frontend_ip_configurations) as f
            left join azure_public_ip as ip on lower(ip.id) = lower(f -> 'properties' -> 'publicIPAddress' ->> 'id')
          where
            (f -> 'properties' -> 'publicIPAddress' ->> 'id') is not null
            and lower(lb.id) = $1
        EOQ

        args = [self.input.lb_id.value]
      }

      with "network_virtual_networks" {
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
              and lower(lb.id) = $1
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
            lower(vn.id) as virtual_network_id
          from
            azure_virtual_network as vn
            right join load_balancer_backend_addresses_list as b on lower(b.vn_id) = lower(vn.id)
          EOQ

        args = [self.input.lb_id.value]
      }

      nodes = [
        node.compute_virtual_machine_scale_set_vm,
        node.compute_virtual_machine_scale_set,
        node.compute_virtual_machine,
        node.network_load_balancer_backend_address_pool,
        node.network_load_balancer_nat_rule,
        node.network_load_balancer_probe,
        node.network_load_balancer_rule,
        node.network_load_balancer_virtual_machine_scale_set_network_interface,
        node.network_load_balancer,
        node.network_network_interface,
        node.network_public_ip,
        node.network_virtual_network,
      ]

      edges = [
        edge.compute_virtual_machine_scale_set_to_network_load_balancer,
        edge.network_load_balancer_backend_address_pool_to_network_interface,
        edge.network_load_balancer_backend_address_pool_to_virtual_network,
        edge.network_load_balancer_to_backend_address_pool,
        edge.network_load_balancer_to_network_load_balancer_nat_rule,
        edge.network_load_balancer_to_network_load_balancer_probe,
        edge.network_load_balancer_to_network_load_balancer_rule,
        edge.network_load_balancer_to_network_public_ip,
        edge.network_network_interface_to_compute_virtual_machine_scale_set_vm,
        edge.network_network_interface_to_compute_virtual_machine,
      ]

      args = {
        compute_virtual_machine_ids                    = with.compute_virtual_machines.rows[*].virtual_machine_id
        compute_virtual_machine_scale_set_ids          = with.compute_virtual_machine_scale_sets.rows[*].compute_virtual_machine_scale_set_id
        compute_virtual_machine_scale_set_vm_ids       = with.compute_virtual_machine_scale_set_vms.rows[*].virtual_machine_scale_set_vm_id
        network_load_balancer_backend_address_pool_ids = with.network_load_balancer_backend_address_pools.rows[*].pool_id
        network_load_balancer_ids                      = [self.input.lb_id.value]
        network_network_interface_ids                  = with.network_network_interfaces.rows[*].network_interface_id
        network_public_ip_ids                          = with.network_public_ips.rows[*].public_ip_id
        network_virtual_network_ids                    = with.network_virtual_networks.rows[*].virtual_network_id
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
        query = query.network_load_balancer_overview
        args = {
          id = self.input.lb_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.network_load_balancer_tags
        args = {
          id = self.input.lb_id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Associated Virtual Machine Scale Sets"
        query = query.load_balancer_associated_virtual_machine_scale_sets
        args = {
          id = self.input.lb_id.value
        }

        column "Name" {
          href = "${dashboard.compute_virtual_machine_scale_set_detail.url_path}?input.vm_scale_set_id={{.'Scale Set ID' | @uri}}"
        }
      }

      table {
        title = "Backend Pools"
        query = query.network_load_balancer_backend_pools
        args = {
          id = self.input.lb_id.value
        }
      }

    }

  }

  container {

    table {
      title = "Frontend IP Configurations"
      query = query.load_balancer_frontend_ip_configurations
      args = {
        id = self.input.lb_id.value
      }
    }
  }

  container {

    table {
      title = "Probes"
      query = query.load_balancer_probe
      args = {
        id = self.input.lb_id.value
      }
    }
  }

  container {

    table {
      title = "Inbound NAT Rules"
      query = query.load_balancer_inbound_nat_rules
      args = {
        id = self.input.lb_id.value
      }
    }

  }

  container {

    table {
      title = "Outbound Rules"
      query = query.load_balancer_outbound_rules
      args = {
        id = self.input.lb_id.value
      }
    }

  }

  container {

    table {
      title = "Load Balancing Rules"
      query = query.load_balancer_load_balancing_rules
      args = {
        id = self.input.lb_id.value
      }
    }
  }

}

query "network_load_balancer_input" {
  sql = <<-EOQ
    select
      lb.title as label,
      lower(lb.id) as value,
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

query "network_load_balancer_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_lb
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_load_balancer_sku_tier" {
  sql = <<-EOQ
    select
      'SKU Tier' as label,
      sku_tier as value
    from
      azure_lb
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_load_balancer_backend_pool_count" {
  sql = <<-EOQ
    select
      'Backend Address Pools' as label,
      jsonb_array_length(backend_address_pools) as value
    from
      azure_lb
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_load_balancer_rules_count" {
  sql = <<-EOQ
    select
      'Load balancing Rules' as label,
      jsonb_array_length(load_balancing_rules) as value
    from
      azure_lb
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_load_nat_rules_count" {
  sql = <<-EOQ
    select
      'Inbound NAT Rules' as label,
      jsonb_array_length(inbound_nat_rules) as value
    from
      azure_lb
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_load_probes_count" {
  sql = <<-EOQ
    select
      'Probes' as label,
      jsonb_array_length(probes) as value
    from
      azure_lb
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_load_balancer_overview" {
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_load_balancer_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_lb,
      jsonb_each_text(tags) as tag
    where
      lower(id) = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "load_balancer_associated_virtual_machine_scale_sets" {
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
      lower(split_part( b ->> 'id', '/backendAddressPools' , 1)) = $1
    EOQ

  param "id" {}
}

query "network_load_balancer_backend_pools" {
  sql = <<-EOQ
    select
      p ->> 'name' as "Name",
      p ->> 'id' as "ID"
    from
      azure_lb,
      jsonb_array_elements(backend_address_pools) as p
    where
      lower(id) = $1;
    EOQ

  param "id" {}
}

query "load_balancer_frontend_ip_configurations" {
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
      lower(id) = $1;
    EOQ

  param "id" {}
}

query "load_balancer_probe" {
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
      lower(id) = $1;
    EOQ

  param "id" {}
}

query "load_balancer_inbound_nat_rules" {
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
      lower(id) = $1;
    EOQ

  param "id" {}
}

query "load_balancer_outbound_rules" {
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
      lower(id) = $1;
    EOQ

  param "id" {}
}

query "load_balancer_load_balancing_rules" {
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
      lower(id) = $1;
    EOQ

  param "id" {}
}









dashboard "network_interface_detail" {

  title         = "Azure Network Interface Detail"
  documentation = file("./dashboards/network/docs/network_interface_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "nic_id" {
    title = "Select a network interface:"
    query = query.network_interface_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.network_interface_private_ip_address
      args  = [self.input.nic_id.value]
    }

    card {
      width = 2
      query = query.network_interface_public_ip_address
      args  = [self.input.nic_id.value]
    }

    card {
      width = 2
      query = query.network_interface_ip_forwarding_enabled
      args  = [self.input.nic_id.value]
    }

    card {
      width = 2
      query = query.network_interface_accelerated_networking_enabled
      args  = [self.input.nic_id.value]
    }

  }

  with "compute_virtual_machines_for_network_interface" {
    query = query.compute_virtual_machines_for_network_interface
    args  = [self.input.nic_id.value]
  }

  with "network_public_ips_for_network_interface" {
    query = query.network_public_ips_for_network_interface
    args  = [self.input.nic_id.value]
  }

  with "network_security_groups_for_network_interface" {
    query = query.network_security_groups_for_network_interface
    args  = [self.input.nic_id.value]
  }

  with "network_subnets_for_network_interface" {
    query = query.network_subnets_for_network_interface
    args  = [self.input.nic_id.value]
  }

  with "network_virtual_networks_for_network_interface" {
    query = query.network_virtual_networks_for_network_interface
    args  = [self.input.nic_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.compute_virtual_machine
        args = {
          compute_virtual_machine_ids = with.compute_virtual_machines_for_network_interface.rows[*].virtual_machine_id
        }
      }

      node {
        base = node.network_network_interface
        args = {
          network_network_interface_ids = [self.input.nic_id.value]
        }
      }

      node {
        base = node.network_network_security_group
        args = {
          network_network_security_group_ids = with.network_security_groups_for_network_interface.rows[*].nsg_id
        }
      }

      node {
        base = node.network_public_ip
        args = {
          network_public_ip_ids = with.network_public_ips_for_network_interface.rows[*].public_ip_id
        }
      }

      node {
        base = node.network_subnet
        args = {
          network_subnet_ids = with.network_subnets_for_network_interface.rows[*].subnet_id
        }
      }

      node {
        base = node.network_virtual_network
        args = {
          network_virtual_network_ids = with.network_virtual_networks_for_network_interface.rows[*].virtual_network_id
        }
      }

      edge {
        base = edge.compute_virtual_machine_to_network_network_interface
        args = {
          compute_virtual_machine_ids = with.compute_virtual_machines_for_network_interface.rows[*].virtual_machine_id
        }
      }

      edge {
        base = edge.network_network_interface_to_network_public_ip
        args = {
          network_network_interface_ids = [self.input.nic_id.value]
        }
      }

      edge {
        base = edge.network_network_interface_to_network_security_group
        args = {
          network_network_interface_ids = [self.input.nic_id.value]
        }
      }

      edge {
        base = edge.network_network_interface_to_network_subnet
        args = {
          network_network_interface_ids = [self.input.nic_id.value]
        }
      }

      edge {
        base = edge.network_subnet_to_network_virtual_network
        args = {
          network_subnet_ids = with.network_subnets_for_network_interface.rows[*].subnet_id
        }
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
        query = query.network_interface_overview
        args  = [self.input.nic_id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.network_interface_tags
        args  = [self.input.nic_id.value]
      }

    }

    container {

      width = 6

      table {
        title = "Attached Virtual Machine"
        query = query.network_interface_attached_virtual_machine
        args  = [self.input.nic_id.value]

        column "Name" {
          href = "${dashboard.compute_virtual_machine_detail.url_path}?input.vm_id={{.ID | @uri}}"
        }

      }

      table {
        title = "Attached Network Security Group"
        query = query.network_interface_attached_nsg
        args  = [self.input.nic_id.value]

        column "Name" {
          href = "${dashboard.network_security_group_detail.url_path}?input.nsg_id={{.ID | @uri}}"
        }
      }

    }
  }

  container {

    width = 12

    table {
      title = "IP Configurations"
      query = query.network_interface_ip_configurations_details
      args  = [self.input.nic_id.value]
    }
  }
}

query "network_interface_input" {
  sql = <<-EOQ
    select
      ni.title as label,
      lower(ni.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', ni.resource_group,
        'region', ni.region
      ) as tags
    from
      azure_network_interface as ni,
      azure_subscription as s
    where
      ni.subscription_id = s.subscription_id
    order by
      ni.title;
  EOQ
}

# card queries

query "network_interface_private_ip_address" {
  sql = <<-EOQ
    select
      'Private IP Address' as label,
      ip -> 'properties' ->> 'privateIPAddress' as value
    from
      azure_network_interface
      cross join jsonb_array_elements(ip_configurations) as ip
    where
      lower(id) = $1;
  EOQ
}

query "network_interface_public_ip_address" {
  sql = <<-EOQ
    with public_ip_address_id as (
      select
        ip -> 'properties' -> 'publicIPAddress' ->> 'id' as public_ip_address
      from
        azure_network_interface as nci
        cross join jsonb_array_elements(ip_configurations) as ip
      where
        lower(nci.id) = $1
    )
    select
      'Public IP Address' as label,
      api.ip_address as value
    from
      azure_public_ip as api,
      public_ip_address_id as pip
    where
      lower(api.id) = lower(pip.public_ip_address);
  EOQ
}

query "network_interface_ip_forwarding_enabled" {
  sql = <<-EOQ
    select
      'IP Forwarding' as label,
      case when enable_ip_forwarding then 'Enabled' else 'Disabled' end as value,
      case when enable_ip_forwarding then 'Ok' else 'Alert' end as type
    from
      azure_network_interface
    where
      lower(id) = $1;
  EOQ
}

query "network_interface_accelerated_networking_enabled" {
  sql = <<-EOQ
    select
      'Accelerated Networking' as label,
      case when enable_accelerated_networking then 'Enabled' else 'Disabled' end as value,
      case when enable_accelerated_networking then 'Ok' else 'Alert' end as type
    from
      azure_network_interface
    where
      lower(id) = $1;
  EOQ
}

# with queries

query "compute_virtual_machines_for_network_interface" {
  sql   = <<-EOQ
    with vm_network_interface_id as (
      select
        id,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
    )
    select
      lower(v.id) as virtual_machine_id
    from
      vm_network_interface_id as v
      left join azure_network_interface as n on lower(v.n_id) = lower(n.id)
    where
      lower(n.id) = $1;
  EOQ
}


query "network_public_ips_for_network_interface" {
  sql = <<-EOQ
    with network_interface_public_ip as (
      select
        id,
        jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
      from
        azure_network_interface
    )
    select
      lower(p.id) as public_ip_id
    from
      network_interface_public_ip as n
      left join azure_public_ip as p on lower(p.id) = lower(n.pid)
    where
      n.pid is not null
      and lower(n.id) = $1;
  EOQ
}

query "network_security_groups_for_network_interface" {
  sql = <<-EOQ
    with network_security_group_id as (
      select
        network_security_group_id as sid,
        id as nid
      from
        azure_network_interface
      where
        lower(id) = $1
    )
  select
    lower(nic.sid) as nsg_id
  from
    network_security_group_id as nic
    left join azure_network_security_group as nsg on lower(nsg.id) = lower(nic.sid)
  where
    lower(nic.sid) is not null;
  EOQ
}

query "network_subnets_for_network_interface" {
  sql = <<-EOQ
    select
      lower(s.id) as subnet_id
    from
      azure_network_interface as ni,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
    where
      lower(ni.id) = $1
      and lower(s.id) is not null;
  EOQ
}

query "network_virtual_networks_for_network_interface" {
  sql  = <<-EOQ
    with subnet_list as(
      select
        ni.id as network_interface_id,
        c -> 'properties' -> 'subnet' ->> 'id' as subnet_id
    from
      azure_network_interface as ni,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on lower(s.id) = lower(c -> 'properties' -> 'subnet' ->> 'id')
    where
      lower(ni.id) = $1
    )
    select
      lower(v.id) as virtual_network_id
    from
      azure_virtual_network as v,
      jsonb_array_elements(subnets) as s,
      subnet_list as l
    where
      lower(l.subnet_id) = lower(s ->> 'id');
  EOQ
}

# table queries

query "network_interface_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      mac_address as "MAC Address",
      provisioning_state as "Provisioning State",
      etag as "ETag",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_network_interface
      cross join jsonb_array_elements(ip_configurations) as ip
    where
      lower(id) = $1;
  EOQ
}

query "azure_network_private_ip" {
  sql = <<-EOQ
    select
      ip ->> 'name' as "Name",
      ip -> 'properties' ->> 'privateIPAddress' as "IP Address",
      ip -> 'properties' ->> 'privateIPAddressVersion' as "Version",
      ip -> 'properties' ->> 'privateIPAllocationMethod' as "Allocation Method",
      ip -> 'properties' ->> 'primary' as "Primary"
    from
      azure_network_interface
      cross join jsonb_array_elements(ip_configurations) as ip
    where
      lower(id) = $1;
  EOQ
}

query "network_interface_tags" {
  sql = <<-EOQ
    select
      jsonb_object_keys(tags) as "Key",
      tags ->> jsonb_object_keys(tags) as "Value"
    from
      azure_network_interface
    where
      id = $1;
  EOQ
}

query "network_interface_attached_virtual_machine" {
  sql = <<-EOQ
    select
      vm.name as "Name",
      lower(vm.id) as "ID"
    from
      azure_network_interface as ni
      left join azure_compute_virtual_machine as vm on lower(vm.id) = lower(ni.virtual_machine_id)
    where
      vm.id is not null
      and lower(ni.id) = $1;
  EOQ
}

query "network_interface_attached_nsg" {
  sql = <<-EOQ
    select
      nsg.name as "Name",
      lower(nsg.id) as "ID"
    from
      azure_network_interface as ni
      left join azure_network_security_group as nsg on lower(nsg.id) = lower(ni.network_security_group_id)
    where
      nsg.id is not null
      and lower(ni.id) = $1;
  EOQ
}


query "network_interface_ip_configurations_details" {
  sql = <<-EOQ
    select
      c ->> 'name' as "Name",
      c -> 'properties' ->> 'primary' as "Primary",
      c -> 'properties' ->> 'privateIPAddress' as "Private IP Address",
      c -> 'properties' ->> 'privateIPAddressVersion' as "Private IP Address Version",
      c -> 'properties' ->> 'privateIPAllocationMethod' as "Private IP Allocation Method",
      c -> 'properties' -> 'subnet' ->> 'id' as "Subnet",
      c ->> 'id' as "ID"
    from
      azure_network_interface,
      jsonb_array_elements(ip_configurations) as c
    where
      lower(id) = $1
    order by
      c ->> 'name';
  EOQ
}

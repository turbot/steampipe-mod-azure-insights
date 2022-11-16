dashboard "azure_network_interface_detail" {

  title         = "Azure Network Interface Detail"
  documentation = file("./dashboards/network/docs/network_interface_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "nic_id" {
    title = "Select a network interface:"
    query = query.azure_network_interface_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_network_interface_private_ip_address
      args = {
        id = self.input.nic_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_interface_public_ip_address
      args = {
        id = self.input.nic_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_interface_ip_forwarding_enabled
      args = {
        id = self.input.nic_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_interface_accelerated_networking_enabled
      args = {
        id = self.input.nic_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azure_network_interface_node,
        node.azure_network_interface_to_network_security_group_node,
        node.azure_network_interface_from_compute_virtual_machine_node,
        node.azure_network_interface_from_public_ip_address_node,
        node.azure_network_interface_to_network_subnet_node,
        node.azure_network_interface_subnet_to_vpc_node
      ]

      edges = [
        edge.azure_network_interface_to_network_security_group_edge,
        edge.azure_network_interface_from_compute_virtual_machine_edge,
        edge.azure_network_interface_from_public_ip_address_edge,
        edge.azure_network_interface_to_security_group_network_subnet_edge,
        edge.azure_network_interface_subnet_to_vpc_edge
      ]

      args = {
        id = self.input.nic_id.value
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
        query = query.azure_network_interface_overview
        args = {
          id = self.input.nic_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_network_interface_tags
        args = {
          id = self.input.nic_id.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Attached Virtual Machine"
        query = query.azure_network_interface_attached_virtual_machine
        args = {
          id = self.input.nic_id.value
        }

        column "Name" {
          href = "${dashboard.azure_compute_virtual_machine_detail.url_path}?input.vm_id={{.ID | @uri}}"
        }

      }

      table {
        title = "Attached Network Security Group"
        query = query.azure_network_interface_attached_nsg
        args = {
          id = self.input.nic_id.value
        }

        column "Name" {
          href = "${dashboard.azure_network_security_group_detail.url_path}?input.nsg_id={{.ID | @uri}}"
        }
      }

    }
  }

  container {

      width = 12

      table {
        title = "IP Configurations"
        query = query.azure_network_interface_ip_configurations_details
        args = {
          id = self.input.nic_id.value
        }
    }
  }
}

query "azure_network_interface_input" {
  sql = <<-EOQ
    select
      ni.title as label,
      ni.id as value,
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

category "azure_network_interface_no_link" {
  icon  = "text:nic"
  color = "purple"
}

node "azure_network_interface_node" {
  category = category.azure_network_interface_no_link

  sql = <<-EOQ
    select
      id as id,
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
      id = $1;
  EOQ

  param "id" {}
}

node "azure_network_interface_to_network_security_group_node" {
  category = category.azure_network_security_group

  sql = <<-EOQ
    with network_security_group_id as (
      select
        network_security_group_id as sid,
        id as nid
      from
        azure_network_interface
    )
    select
      nsg.id as id,
      nsg.title as title,
      json_build_object(
        'Name', nsg.name,
        'ID', nsg.id,
        'Subscription ID', nsg.subscription_id,
        'Resource Group', nsg.resource_group,
        'Region', nsg.region
      ) as properties
    from
      azure_network_security_group as nsg
      left join network_security_group_id as nic on nsg.id = nic.sid
    where
      nic.nid = $1
  EOQ

  param "id" {}
}

edge "azure_network_interface_to_network_security_group_edge" {
  title = "nsg"
  sql   = <<-EOQ
    with network_security_group_id as (
      select
        network_security_group_id as sid,
        id as nid
      from
        azure_network_interface
    )
    select
      nsg.id as to_id,
      nic.nid as from_id
    from
      azure_network_security_group as nsg
      left join network_security_group_id as nic on nsg.id = nic.sid
    where
      nic.nid = $1
  EOQ

  param "id" {}
}

node "azure_network_interface_to_network_subnet_node" {
  category = category.azure_subnet

  sql = <<-EOQ
    select
      s.id as id,
      s.title as title,
      json_build_object(
        'Name', s.name,
        'ID', s.id,
        'Subscription ID', s.subscription_id,
        'Resource Group', s.resource_group
      ) as properties
    from
      azure_network_interface as ni,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on s.id = c -> 'properties' -> 'subnet' ->> 'id'
    where
      ni.id = $1
  EOQ

  param "id" {}
}

edge "azure_network_interface_to_security_group_network_subnet_edge" {
  title = "subnet"

  sql   = <<-EOQ
    select
      s.id as to_id,
      coalesce(
        ni.network_security_group_id,
        ni.id
      ) as from_id
    from
      azure_network_interface as ni,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on s.id = c -> 'properties' -> 'subnet' ->> 'id'
    where
      ni.id = $1;
  EOQ

  param "id" {}
}

node "azure_network_interface_subnet_to_vpc_node" {
  category = category.azure_virtual_network

  sql = <<-EOQ
    with subnet_list as (
      select
        ni.id as network_interface_id,
        c -> 'properties' -> 'subnet' ->> 'id' as subnet_id
    from
      azure_network_interface as ni,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on s.id = c -> 'properties' -> 'subnet' ->> 'id'
    where
      ni.id = $1
    )
    select
      v.id as id,
      v.title as title,
      json_build_object(
        'Name', v.name,
        'ID', v.id,
        'Subscription ID', v.subscription_id,
        'Resource Group', v.resource_group
      ) as properties
    from
      azure_virtual_network as v,
      jsonb_array_elements(subnets) as s,
      subnet_list as l
    where
      lower(l.subnet_id) = lower(s ->> 'id')
      and l.network_interface_id = $1
  EOQ

  param "id" {}
}

edge "azure_network_interface_subnet_to_vpc_edge" {
  title = "virtual network"

  sql = <<-EOQ
    with subnet_list as (
      select
        ni.id as network_interface_id,
        c -> 'properties' -> 'subnet' ->> 'id' as subnet_id
    from
      azure_network_interface as ni,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on s.id = c -> 'properties' -> 'subnet' ->> 'id'
    where
      ni.id = $1
    )
    select
      v.id as to_id,
      l.subnet_id as from_id
    from
      azure_virtual_network as v,
      jsonb_array_elements(subnets) as s,
      subnet_list as l
    where
      lower(l.subnet_id) = lower(s ->> 'id')
      and l.network_interface_id = $1
  EOQ

  param "id" {}
}

node "azure_network_interface_from_compute_virtual_machine_node" {
  category = category.azure_compute_virtual_machine

  sql = <<-EOQ
    with vm_network_interface_id as (
      select
        id,
        name,
        subscription_id,
        resource_group,
        title,
        region,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
    )
    select
      v.id as id,
      v.title as title,
      jsonb_build_object(
        'Name', v.name,
        'ID', v.id,
        'Subscription ID', v.subscription_id,
        'Resource Group', v.resource_group,
        'Region', v.region
      ) as properties
    from
      vm_network_interface_id as v
      left join azure_network_interface as n on v.n_id = n.id
    where
      n.id = $1;
  EOQ

  param "id" {}
}

edge "azure_network_interface_from_compute_virtual_machine_edge" {
  title = "attached to"

  sql = <<-EOQ
    with vm_network_interface_id as (
      select
        id,
        name,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
    )
    select
      v.id as from_id,
      n.id as to_id
    from
      vm_network_interface_id as v
      left join azure_network_interface as n on v.n_id = n.id
    where
      n.id = $1;
  EOQ

  param "id" {}
}

node "azure_network_interface_from_public_ip_address_node" {
  category = category.azure_public_ip

  sql = <<-EOQ
    with network_interface_public_ip as (
      select
        id,
        title,
        subscription_id,
        resource_group,
        region,
        jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
      from
        azure_network_interface
    )
    select
      p.id as id,
      p.title as title,
      jsonb_build_object(
        'Title', p.title,
        'Subscription ID', p.subscription_id,
        'Resource Group', p.resource_group,
        'Region', p.region
      ) as properties
    from
      network_interface_public_ip as n
      left join azure_public_ip as p on p.id = n.pid
    where
      n.id = $1;
  EOQ

  param "id" {}
}

edge "azure_network_interface_from_public_ip_address_edge" {
  title = "network interface"

  sql = <<-EOQ
    with network_interface_public_ip as (
      select
        id,
        jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
      from
        azure_network_interface
    )
    select
      p.id as from_id,
      n.id as to_id
    from
      network_interface_public_ip as n
      left join azure_public_ip as p on p.id = n.pid
    where
      n.id = $1;
  EOQ

  param "id" {}
}

query "azure_network_interface_private_ip_address" {
  sql = <<-EOQ
    select
      'Private IP Address' as label,
      ip -> 'properties' ->> 'privateIPAddress' as value
    from
      azure_network_interface
      cross join jsonb_array_elements(ip_configurations) as ip
      where
        id = $1;
  EOQ

  param "id" {}
}

query "azure_network_interface_public_ip_address" {
  sql = <<-EOQ
  with public_ip_address_id as (
  select
      ip -> 'properties' -> 'publicIPAddress' ->> 'id' as public_ip_address
    from
      azure_network_interface as nci
      cross join jsonb_array_elements(ip_configurations) as ip
    where nci.id = $1
  )
    select 'Public IP Address' as label,
      api.ip_address as value
    from
      azure_public_ip as api,
      public_ip_address_id as pip
    where
      api.id = pip.public_ip_address;
  EOQ

  param "id" {}
}

query "azure_network_interface_ip_forwarding_enabled" {
  sql = <<-EOQ
    select
      'IP Forwarding' as label,
      case when enable_ip_forwarding then 'Enabled' else 'Disabled' end as value,
      case when enable_ip_forwarding then 'Ok' else 'Alert' end as type
    from
      azure_network_interface
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_interface_accelerated_networking_enabled" {
  sql = <<-EOQ
    select
      'Accelerated Networking' as label,
      case when enable_accelerated_networking then 'Enabled' else 'Disabled' end as value,
      case when enable_accelerated_networking then 'Ok' else 'Alert' end as type
    from
      azure_network_interface
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_interface_overview" {
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
      id = $1;
  EOQ

  param "id" {}
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
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_interface_tags" {
  sql = <<-EOQ
  select
    jsonb_object_keys(tags) as "Key",
    tags ->> jsonb_object_keys(tags) as "Value"
  from
    azure_network_interface
  where
    id = $1;
  EOQ

  param "id" {}
}

query "azure_network_interface_attached_virtual_machine" {
  sql = <<-EOQ
    select
      vm.name as "Name",
      vm.id as "ID"
    from
      azure_network_interface as ni
      left join azure_compute_virtual_machine as vm on lower(vm.id) = lower(ni.virtual_machine_id)
    where
      ni.id = $1;
  EOQ

  param "id" {}
}

query "azure_network_interface_attached_nsg" {
  sql = <<-EOQ
    select
      nsg.name as "Name",
      nsg.id as "ID"
    from
      azure_network_interface as ni
      left join azure_network_security_group as nsg on lower(nsg.id) = lower(ni.network_security_group_id)
    where
      ni.id = $1;
  EOQ

  param "id" {}
}


query "azure_network_interface_ip_configurations_details" {
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
      id = $1;
  EOQ

  param "id" {}
}

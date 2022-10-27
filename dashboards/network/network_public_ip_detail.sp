dashboard "azure_network_public_ip_detail" {

  title         = "Azure Network Public IP Detail"
  // documentation = file("./dashboards/vpc/docs/vpc_eip_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "nip_id" {
    title = "Select a public ip:"
    query = query.azure_network_public_ip_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_network_public_ip_address
      args = {
        id = self.input.nip_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_public_ip_sku_name
      args = {
        id = self.input.nip_id.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azure_network_public_ip_node,
        node.azure_network_public_ip_from_network_interface_node,
        node.azure_network_public_ip_network_interface_from_compute_virtual_machine_node,
        node.azure_network_public_ip_from_api_management_node
      ]

      edges = [
        edge.azure_network_public_ip_from_network_interface_edge,
        edge.azure_network_public_ip_network_interface_from_compute_virtual_machine_edge,
        edge.azure_network_public_ip_from_api_management_edge
      ]

      args = {
        id = self.input.nip_id.value
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
        query = query.azure_network_public_ip_overview
        args = {
          id = self.input.nip_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_network_public_ip_tags
        args = {
          id = self.input.nip_id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Association"
        query = query.azure_network_public_ip_association_details
        args = {
          id = self.input.nip_id.value
        }
      }
    }
  }
}

query "azure_network_public_ip_input" {
  sql = <<-EOQ
    select
      p.title as label,
      p.id as value,
      json_build_object(
        'Name', p.name,
        'ID', p.id,
        'Subscription ID', p.subscription_id,
        'Resource Group', p.resource_group,
        'Region', p.region
      ) as tags
    from
      azure_public_ip as p,
      azure_subscription as s
    where
      p.subscription_id = s.subscription_id
    order by
      p.title;
  EOQ
}

node "azure_network_public_ip_node" {
  category = category.azure_public_ip

  sql = <<-EOQ
    select
      id as id,
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
      id = $1;
  EOQ

  param "id" {}
}

node "azure_network_public_ip_from_network_interface_node" {
  category = category.azure_network_interface

  sql = <<-EOQ
    with network_interface_public_ip as (
      select
        id,
        title,
        provisioning_state,
        subscription_id,
        resource_group,
        region,
        jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
      from
        azure_network_interface
    )
    select
      n.id as id,
      n.title as title,
      jsonb_build_object(
        'Title', n.title,
        'Provisioning State', n.provisioning_state,
        'Subscription ID', n.subscription_id,
        'Resource Group', n.resource_group,
        'Region', n.region
      ) as properties
    from
      network_interface_public_ip as n
      left join azure_public_ip as p on n.pid = p.id
    where
      p.id = $1;
  EOQ

  param "id" {}
}

edge "azure_network_public_ip_from_network_interface_edge" {
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
      n.id as from_id,
      p.id as to_id
    from
      network_interface_public_ip as n
      left join azure_public_ip as p on n.pid = p.id
    where
      p.id = $1;
  EOQ

  param "id" {}
}

node "azure_network_public_ip_network_interface_from_compute_virtual_machine_node" {
  category = category.azure_compute_virtual_machine

  sql = <<-EOQ
    with vm_network_interface as (
      select
        id,
        title,
        provisioning_state,
        subscription_id,
        resource_group,
        region,
        jsonb_array_elements(network_interfaces)->>'id' as n_id
      from
        azure_compute_virtual_machine
    ),  ni_public_ip as (
          select
            id,
            jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
          from
            azure_network_interface
        )
    select
      v.id as id,
      v.title as title,
      jsonb_build_object(
        'Title', v.title,
        'Provisioning State', v.provisioning_state,
        'Subscription ID', v.subscription_id,
        'Resource Group', v.resource_group,
        'Region', v.region
      ) as properties
    from
      vm_network_interface as v
      left join ni_public_ip as n on v.n_id = n.id
      left join azure_public_ip as p on n.pid = p.id
    where
      p.id = $1;
  EOQ

  param "id" {}
}

edge "azure_network_public_ip_network_interface_from_compute_virtual_machine_edge" {
  title = "virtual machine"

  sql = <<-EOQ
    with vm_network_interface as (
      select
        id,
        title,
        provisioning_state,
        subscription_id,
        resource_group,
        region,
        jsonb_array_elements(network_interfaces)->>'id' as nid
      from
        azure_compute_virtual_machine
    ),
    ni_public_ip as (
      select
        id,
        jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
      from
        azure_network_interface
    )
    select
      v.id as from_id,
      n.id as to_id
    from
      vm_network_interface as v
      left join ni_public_ip as n on v.nid = n.id
      left join azure_public_ip as p on n.pid = p.id
    where
      p.id = $1;
  EOQ

  param "id" {}
}

node "azure_network_public_ip_from_api_management_node" {
  category = category.azure_api_management

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
      a.id as id,
      a.title as title,
      jsonb_build_object(
        'Title', a.title,
        'Provisioning State', a.provisioning_state,
        'Subscription ID', a.subscription_id,
        'Resource Group', a.resource_group,
        'Region', a.region
      ) as properties
    from
      public_ip_api_management as a
      left join azure_public_ip as p on (a.pid)::inet = p.ip_address
    where
      p.id = $1;
  EOQ

  param "id" {}
}

edge "azure_network_public_ip_from_api_management_edge" {
  title = "api management"

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
      a.id as from_id,
      p.id as to_id
    from
      public_ip_api_management as a
      left join azure_public_ip as p on (a.pid)::inet = p.ip_address
    where
      p.id = $1;
  EOQ

  param "id" {}
}

query "azure_network_public_ip_address" {
  sql = <<-EOQ
    select
      'Public IP Address' as label,
      ip_address as value
    from
      azure_public_ip
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_public_ip_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_public_ip
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_public_ip_ddos_settings_protected_ip" {
  sql = <<-EOQ
    select
      ddos_settings_protection_coverage as label,
      ddos_settings_protected_ip as value
    from
      azure_public_ip
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_public_ip_overview" {
  sql = <<-EOQ
    select
      ip_address as "IP Address",
      resource_group as "Resource Group",
      title as "Title",
      region as "Region",
      ip_configuration_id as "IP Configuration ID",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_public_ip
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_public_ip_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      azure_public_ip
    where
      id = $1
    order by
      tags ->> 'Key';
  EOQ

  param "id" {}
}

query "azure_network_public_ip_association_details" {
  sql = <<-EOQ
     -- Network Interface
    with network_interface_public_ip as (
      select
        id,
        title,
        type,
        jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
      from
        azure_network_interface
    ),  public_ip_api_management as (
      select
        id,
        title,
        type,
        jsonb_array_elements_text(public_ip_addresses) as pid
      from
        azure_api_management
    )

    select
      n.title as "Title",
      n.type as  "Type",
      n.id as "ID",
      null as link
    from
      network_interface_public_ip as n
      left join azure_public_ip as p on n.pid = p.id
    where
      p.id = $1


    -- API Management
    union all

    select
      a.title as "Title",
      a.type as  "Type",
      a.id as "ID",
      null as link
    from
      public_ip_api_management as a
      left join azure_public_ip as p on (a.pid)::inet = p.ip_address
    where
      p.id = $1
  EOQ

  param "id" {}
}

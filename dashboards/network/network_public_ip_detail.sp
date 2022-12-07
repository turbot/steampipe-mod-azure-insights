dashboard "network_public_ip_detail" {

  title         = "Azure Network Public IP Detail"
  documentation = file("./dashboards/network/docs/network_public_ip_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "public_ip_id" {
    title = "Select a public IP:"
    query = query.network_public_ip_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.network_public_association
      args = {
        id = self.input.public_ip_id.value
      }
    }

    card {
      width = 2
      query = query.network_public_ip_address
      args = {
        id = self.input.public_ip_id.value
      }
    }

    card {
      width = 2
      query = query.network_public_ip_sku_name
      args = {
        id = self.input.public_ip_id.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "compute_virtual_machines" {
        sql = <<-EOQ
          with vm_network_interface as (
            select
              id,
              jsonb_array_elements(network_interfaces)->>'id' as n_id
            from
              azure_compute_virtual_machine
          ), ni_public_ip as (
              select
                id,
                jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
              from
                azure_network_interface
          )
          select
            lower(v.id) as virtual_machine_id
          from
            vm_network_interface as v
            left join ni_public_ip as n on lower(v.n_id) = lower(n.id)
            left join azure_public_ip as p on lower(n.pid) = lower(p.id)
          where
            lower(p.id) = $1;
          EOQ

        args = [self.input.public_ip_id.value]
      }

      with "network_network_interfaces" {
        sql = <<-EOQ
          with network_interface_public_ip as (
            select
              id,
              jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
            from
              azure_network_interface
          )
          select
            lower(n.id) as nic_id
          from
            network_interface_public_ip as n
            left join azure_public_ip as p on lower(n.pid) = lower(p.id)
          where
            lower(p.id) = $1;
        EOQ

        args = [self.input.public_ip_id.value]
      }

      nodes = [
        node.compute_virtual_machine,
        node.network_network_interface,
        node.network_public_ip_api_management,
        node.network_public_ip,
      ]

      edges = [
        edge.compute_virtual_machine_to_network_network_interface,
        edge.network_network_interface_to_network_public_ip,
        edge.network_public_ip_to_api_management,
      ]

      args = {
        compute_virtual_machine_ids   = with.compute_virtual_machines.rows[*].virtual_machine_id
        network_network_interface_ids = with.network_network_interfaces.rows[*].nic_id
        network_public_ip_ids         = [self.input.public_ip_id.value]
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
        query = query.network_public_ip_overview
        args = {
          id = self.input.public_ip_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.network_public_ip_tags
        args = {
          id = self.input.public_ip_id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Association"
        query = query.network_public_ip_association_details
        args = {
          id = self.input.public_ip_id.value
        }
      }
    }
  }
}

query "network_public_ip_input" {
  sql = <<-EOQ
    select
      p.title as label,
      lower(p.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', p.resource_group,
        'region', p.region
      ) as tags
    from
      azure_public_ip as p,
      azure_subscription as s
    where
      lower(p.subscription_id) = lower(s.subscription_id)
    order by
      p.title;
  EOQ
}

query "network_public_association" {
  sql = <<-EOQ
    select
      'Association' as label,
      case when ip_configuration_id is not null then 'Associated' else 'Not Associated' end as value,
      case when ip_configuration_id is not null then 'ok' else 'alert' end as type
    from
      azure_public_ip
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_public_ip_address" {
  sql = <<-EOQ
    select
      'Public IP Address' as label,
      ip_address as value
    from
      azure_public_ip
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_public_ip_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_public_ip
    where
      lower(id) = $1;
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
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_public_ip_overview" {
  sql = <<-EOQ
    select
      ip_address as "IP Address",
      public_ip_allocation_method as "Public IP Allocation Method",
      public_ip_address_version as "Public IP Address Version",
      ip_configuration_id as "IP Configuration ID",
      title as "Title",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_public_ip
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_public_ip_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      azure_public_ip
    where
      lower(id) = $1
    order by
      tags ->> 'Key';
  EOQ

  param "id" {}
}

query "network_public_ip_association_details" {
  sql = <<-EOQ

    with network_interface_public_ip as (
      select
        id,
        title,
        type,
        jsonb_array_elements(ip_configurations)->'properties'->'publicIPAddress'->>'id' as pid
      from
        azure_network_interface
    ), public_ip_api_management as (
        select
          id,
          title,
          type,
          jsonb_array_elements_text(public_ip_addresses) as pid
        from
          azure_api_management
    )
    -- Network Interface
    select
      n.title as "Title",
      n.type as  "Type",
      n.id as "ID",
      null as link
    from
      network_interface_public_ip as n
      left join azure_public_ip as p on lower(n.pid) = lower(p.id)
    where
      lower(p.id) = $1

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
      lower(p.id) = $1
  EOQ

  param "id" {}
}

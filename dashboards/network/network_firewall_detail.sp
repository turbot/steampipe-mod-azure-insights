dashboard "azure_network_firewall_detail" {

  title         = "Azure Network Firewall Detail"
  documentation = file("./dashboards/network/docs/network_firewall_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "firewall_id" {
    title = "Select a firewall:"
    query = query.azure_network_firewall_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_network_firewall_sku_name
      args = {
        id = self.input.firewall_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_firewall_sku_tier
      args = {
        id = self.input.firewall_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_firewall_threat_intel_mode
      args = {
        id = self.input.firewall_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azure_network_firewall_node,
        node.azure_network_firewall_to_public_ip_node,
        node.azure_network_firewall_to_subnet_node,
        node.azure_network_firewall_subnet_to_virtual_machine_node
      ]

      edges = [
        edge.azure_network_firewall_to_public_ip_edge,
        edge.azure_network_firewall_to_subnet_edge,
        edge.azure_network_firewall_subnet_to_virtual_machine_edge
      ]

      args = {
        id = self.input.firewall_id.value
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
        query = query.azure_network_firewall_overview
        args = {
          id = self.input.firewall_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_network_firewall_tags
        args = {
          id = self.input.firewall_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "IP Configurations"
        query = query.azure_network_firewall_ip_configurations
        args = {
          id = self.input.firewall_id.value
        }
      }
    }

  }

}

query "azure_network_firewall_input" {
  sql = <<-EOQ
    select
      f.title as label,
      f.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', f.resource_group,
        'region', f.region
      ) as tags
    from
      azure_firewall as f,
      azure_subscription as s
    where
      f.subscription_id = s.subscription_id
    order by
      f.title;
  EOQ
}

query "azure_network_firewall_sku_name" {
  sql = <<-EOQ
    select
      'SKU Name' as label,
      sku_name as value
    from
      azure_firewall
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_firewall_sku_tier" {
  sql = <<-EOQ
    select
      'SKU Tier' as label,
      sku_tier as value
    from
      azure_firewall
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_firewall_threat_intel_mode" {
  sql = <<-EOQ
    select
      'Threat Intel Mode' as label,
      threat_intel_mode as value
    from
      azure_firewall
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_firewall_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      provisioning_state as "Provisioning State",
      etag as "Etag",
      type as "Type",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_firewall
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_firewall_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_firewall,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_network_firewall_ip_configurations" {
  sql = <<-EOQ
    select
      c ->> 'privateIPAddress' as "Private IP Address",
      c ->> 'provisioningState' as "Provisioning State",
      c -> 'publicIPAddress' ->> 'id' as "Public IP Address ID",
      c -> 'subnet' ->> 'id' as "Subnet ID"
    from
      azure_firewall,
      jsonb_array_elements(ip_configurations) as c
    where
      id = $1;
    EOQ

  param "id" {}
}

category "azure_network_firewall_no_link" {
  icon = local.azure_firewall_icon
}

node "azure_network_firewall_node" {
  category = category.azure_network_firewall_no_link

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
      azure_firewall
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_network_firewall_to_public_ip_node" {
  category = category.azure_firewall

  sql = <<-EOQ
    select
      ip.id as id,
      ip.title as title,
      jsonb_build_object(
        'ID', ip.id,
        'Name', ip.name,
        'Type', ip.type,
        'Region', ip.region,
        'Resource Group', ip.resource_group,
        'Subscription ID', ip.subscription_id
      ) as properties
    from
      azure_firewall as f,
      jsonb_array_elements(ip_configurations) as c
      left join azure_public_ip as ip on ip.id = c -> 'publicIPAddress' ->> 'id'
    where
      f.id = $1;
  EOQ

  param "id" {}
}

edge "azure_network_firewall_to_public_ip_edge" {
  title = "public ip"

  sql = <<-EOQ
    select
      f.id as from_id,
      ip.id as to_id
    from
      azure_firewall as f,
      jsonb_array_elements(ip_configurations) as c
      left join azure_public_ip as ip on ip.id = c -> 'publicIPAddress' ->> 'id'
    where
      f.id = $1;
  EOQ

  param "id" {}
}

node "azure_network_firewall_to_subnet_node" {
  category = category.azure_subnet

  sql = <<-EOQ
    select
      s.id as id,
      s.title as title,
      jsonb_build_object(
        'ID', s.id,
        'Name', s.name,
        'Type', s.type,
        'Resource Group', s.resource_group,
        'Subscription ID', s.subscription_id
      ) as properties
    from
      azure_firewall as f,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on s.id = c -> 'subnet' ->> 'id'
    where
      f.id = $1;
  EOQ

  param "id" {}
}

edge "azure_network_firewall_to_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      f.id as from_id,
      s.id as to_id
    from
      azure_firewall as f,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on s.id = c -> 'subnet' ->> 'id'
    where
      f.id = $1;
  EOQ

  param "id" {}
}

node "azure_network_firewall_subnet_to_virtual_machine_node" {
  category = category.azure_virtual_network

  sql = <<-EOQ
    with subnet_list as (
      select
        f.id as firewall_id,
        s.id as subnet_id
    from
      azure_firewall as f,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on s.id = c -> 'subnet' ->> 'id'
    where
      f.id = '/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/demo/providers/Microsoft.Network/azureFirewalls/firewall1'
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
      azure_virtual_network as vn,
      jsonb_array_elements(subnets) as s,
      subnet_list as sub
    where
      s ->> 'id' = sub.subnet_id
  EOQ

  param "id" {}
}

edge "azure_network_firewall_subnet_to_virtual_machine_edge" {
  title = "virtual network"

  sql = <<-EOQ
    with subnet_list as (
      select
        f.id as firewall_id,
        s.id as subnet_id
    from
      azure_firewall as f,
      jsonb_array_elements(ip_configurations) as c
      left join azure_subnet as s on s.id = c -> 'subnet' ->> 'id'
    where
      f.id = '/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/demo/providers/Microsoft.Network/azureFirewalls/firewall1'
    )
    select
      sub.subnet_id as from_id,
      vn.id as to_id
    from
      azure_virtual_network as vn,
      jsonb_array_elements(subnets) as s,
      subnet_list as sub
    where
      s ->> 'id' = sub.subnet_id
  EOQ

  param "id" {}
}
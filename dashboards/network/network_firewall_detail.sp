dashboard "network_firewall_detail" {

  title         = "Azure Network Firewall Detail"
  documentation = file("./dashboards/network/docs/network_firewall_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "firewall_id" {
    title = "Select a firewall:"
    query = query.network_firewall_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.network_firewall_sku_name
      args = {
        id = self.input.firewall_id.value
      }
    }

    card {
      width = 2
      query = query.network_firewall_sku_tier
      args = {
        id = self.input.firewall_id.value
      }
    }

    card {
      width = 2
      query = query.network_firewall_threat_intel_mode
      args = {
        id = self.input.firewall_id.value
      }
    }

  }

  # container {

  #   graph {
  #     title     = "Relationships"
  #     type      = "graph"
  #     direction = "TD"

  #     with "network_public_ips" {
  #       sql = <<-EOQ
  #         select
  #           lower(ip.id) as public_ip_id
  #         from
  #           azure_firewall as f,
  #           jsonb_array_elements(ip_configurations) as c
  #           left join azure_public_ip as ip on lower(ip.id) = lower(c -> 'publicIPAddress' ->> 'id')
  #         where
  #           lower(f.id) = $1;
  #       EOQ

  #       args = [self.input.firewall_id.value]
  #     }

  #     with "network_subnets" {
  #       sql = <<-EOQ
  #         select
  #           lower(s.id) as subnet_id
  #         from
  #           azure_firewall as f,
  #           jsonb_array_elements(ip_configurations) as c
  #           left join azure_subnet as s on lower(s.id) = lower(c -> 'subnet' ->> 'id')
  #         where
  #           lower(f.id) = $1;
  #       EOQ

  #       args = [self.input.firewall_id.value]
  #     }

  #     with "network_virtual_networks" {
  #       sql = <<-EOQ
  #         with subnet_list as (
  #           select
  #             f.id as firewall_id,
  #             s.id as subnet_id
  #         from
  #           azure_firewall as f,
  #           jsonb_array_elements(ip_configurations) as c
  #           left join azure_subnet as s on lower(s.id) = lower(c -> 'subnet' ->> 'id')
  #         where
  #           lower(f.id) = $1
  #         )
  #         select
  #           lower(vn.id) as network_id
  #         from
  #           azure_virtual_network as vn,
  #           jsonb_array_elements(subnets) as s,
  #           subnet_list as sub
  #         where
  #           lower(s ->> 'id') = lower(sub.subnet_id)
  #       EOQ

  #       args = [self.input.firewall_id.value]
  #     }

  #     nodes = [
  #       node.network_firewall,
  #       node.network_public_ip,
  #       node.network_subnet,
  #       node.network_virtual_network
  #     ]

  #     edges = [
  #       edge.network_firewall_to_network_public_ip,
  #       edge.network_firewall_to_network_subnet,
  #       edge.network_subnet_to_network_virtual_network
  #     ]

  #     args = {
  #       network_firewall_ids        = [self.input.firewall_id.value]
  #       network_public_ip_ids       = with.network_public_ips.rows[*].public_ip_id
  #       network_subnet_ids          = with.network_subnets.rows[*].subnet_id
  #       network_virtual_network_ids = with.network_virtual_networks.rows[*].network_id
  #     }
  #   }
  # }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.network_firewall_overview
        args = {
          id = self.input.firewall_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.network_firewall_tags
        args = {
          id = self.input.firewall_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "IP Configurations"
        query = query.network_firewall_ip_configurations
        args = {
          id = self.input.firewall_id.value
        }
      }
    }

  }

}

query "network_firewall_input" {
  sql = <<-EOQ
    select
      f.title as label,
      lower(f.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', f.resource_group,
        'region', f.region
      ) as tags
    from
      azure_firewall as f,
      azure_subscription as s
    where
      lower(f.subscription_id) = lower(s.subscription_id)
    order by
      f.title;
  EOQ
}

query "network_firewall_sku_name" {
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

query "network_firewall_sku_tier" {
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

query "network_firewall_threat_intel_mode" {
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

query "network_firewall_overview" {
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

query "network_firewall_tags" {
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

query "network_firewall_ip_configurations" {
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

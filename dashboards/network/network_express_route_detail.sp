dashboard "network_express_route_detail" {

  title         = "Azure Express Route Circuit Detail"
  documentation = file("./dashboards/network/docs/network_express_route_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "er_id" {
    title = "Select an Express Route Circuit:"
    query = query.express_route_circuit_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.network_express_route_sku
      args  = [self.input.er_id.value]
    }

    card {
      width = 2
      query = query.network_express_route_service_provider
      args  = [self.input.er_id.value]
    }

    card {
      width = 2
      query = query.network_express_route_allow_classic_operations
      args  = [self.input.er_id.value]
    }

    card {
      width = 2
      query = query.network_express_route_global_reach
      args  = [self.input.er_id.value]
    }

    card {
      width = 2
      query = query.network_express_route_peering_count
      args  = [self.input.er_id.value]
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.network_express_route_overview
        args  = [self.input.er_id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.network_express_route_tags
        args  = [self.input.er_id.value]
      }
    }

    container {
      width = 6

      table {
        title = "Service Provider Properties"
        query = query.network_express_route_service_provider_properties
        args  = [self.input.er_id.value]
      }

      table {
        title = "SKU"
        query = query.network_express_route_sku_details
        args  = [self.input.er_id.value]
      }

    }

  }
  container {

    title = "Peering Details"

    table {
      width = 12
      query = query.network_express_route_peerings
      args  = [self.input.er_id.value]
    }

    table {
      title = "Primary Peer"
      width = 6
      query = query.network_express_route_peerings_primary
      args  = [self.input.er_id.value]
    }

    table {
      title = "Secondary Peer"
      width = 6
      query = query.network_express_route_peerings_secondary
      args  = [self.input.er_id.value]
    }
  }

}

query "express_route_circuit_input" {
  sql = <<-EOQ
    select
      n.title as label,
      lower(n.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', n.resource_group,
        'region', n.region
      ) as tags
    from
      azure_express_route_circuit as n,
      azure_subscription as s
    where
      lower(n.subscription_id) = lower(s.subscription_id)
    order by
      n.title;
  EOQ
}

query "network_express_route_peering_count" {
  sql = <<-EOQ
    select
      'Peerings' as label,
      jsonb_array_length(peerings) as value,
      case when jsonb_array_length(peerings) > 0 then 'ok' else 'alert' end as type
    from
      azure_express_route_circuit
    where
      lower(id) = $1;
  EOQ
}

query "network_express_route_sku" {
  sql = <<-EOQ
    select
      'SKU' as label,
      sku_tier as value
    from
      azure_express_route_circuit
    where
      lower(id) = $1;
  EOQ
}

query "network_express_route_service_provider" {
  sql = <<-EOQ
    select
      'Service Provider' as label,
      service_provider_properties ->> 'serviceProviderName' as value
    from
      azure_express_route_circuit
    where
      lower(id) = $1;
  EOQ
}

query "network_express_route_allow_classic_operations" {
  sql = <<-EOQ
    select
      'Classic Operations' as label,
      case when allow_classic_operations then 'enabled' else 'disabled' end as value
    from
      azure_express_route_circuit
    where
      lower(id) = $1;
  EOQ
}

query "network_express_route_global_reach" {
  sql = <<-EOQ
    select
      'Global Reach' as label,
      case when global_reach_enabled then 'enabled' else 'disabled' end as value
    from
      azure_express_route_circuit
    where
      lower(id) = $1;
  EOQ
}

# table queries


query "network_express_route_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      etag as "ETag",
      service_key as "Service Key",
      circuit_provisioning_state as "Circuit Provisioning State",
      service_provider_provisioning_state as "Service Provider Provisioning State",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_express_route_circuit
    where
      lower(id) = $1
  EOQ
}

query "network_express_route_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_express_route_circuit,
      jsonb_each_text(tags) as tag
    where
      tag.key <> 'NAME' and
      lower(id) = $1
    order by
      name;
  EOQ
}

query "network_express_route_service_provider_properties" {
  sql = <<-EOQ
    select
      service_provider_properties ->> 'serviceProviderName' as "Name",
      service_provider_properties ->> 'bandwidthInMbps' as "Bandwidth In Mbps",
      service_provider_properties ->> 'peeringLocation' as "Peering Location"
    from
      azure_express_route_circuit
    where
      lower(id) = $1;
  EOQ
}

query "network_express_route_sku_details" {
  sql = <<-EOQ
    select
      sku_name as "Name",
      sku_family as "Family",
      sku_tier as "Tier"
    from
      azure_express_route_circuit
    where
      lower(id) = $1;
  EOQ
}

query "network_express_route_peerings" {
  sql = <<-EOQ
    select
      name,
      replace(jsonb_path_query(peerings, '$.properties.azureASN')::text, '"', '') as "Azure ASN",
      replace(jsonb_path_query(peerings, '$.properties.connections')::text, '"', '') as "Connections",
      replace(jsonb_path_query(peerings, '$.properties.gatewayManagerEtag')::text, '"', '') as "Gateway Manager Etag",
      replace(jsonb_path_query(peerings, '$.properties.peerASN')::text, '"', '') as "Peer ASN",
      replace(jsonb_path_query(peerings, '$.properties.peeringType')::text, '"', '') as "Peering Type",
      replace(jsonb_path_query(peerings, '$.properties.state')::text, '"', '') as "State",
      replace(jsonb_path_query(peerings, '$.properties.vlanId')::text, '"', '') as "VlanId"
    from
      azure_express_route_circuit
    where
      lower(id) = $1
    order by
      name;
  EOQ
}

query "network_express_route_peerings_primary" {
  sql = <<-EOQ
    select
      name,
      replace(jsonb_path_query(peerings, '$.properties.primaryAzurePort')::text, '"', '') as "Primary Azure Port",
      replace(jsonb_path_query(peerings, '$.properties.primaryPeerAddressPrefix')::text, '"', '') as "Primary Peer Address Prefix"
    from
      azure_express_route_circuit
    where
      lower(id) = $1
    order by
      name;
  EOQ
}

query "network_express_route_peerings_secondary" {
  sql = <<-EOQ
    select
      name,
      replace(jsonb_path_query(peerings, '$.properties.secondaryAzurePort')::text, '"', '') as "Secondary Azure Port",
      replace(jsonb_path_query(peerings, '$.properties.secondaryPeerAddressPrefix')::text, '"', '') as "Secondary Peer Address Prefix"
    from
      azure_express_route_circuit
    where
      lower(id) = $1
    order by
      name;
  EOQ
}
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

    title = "Peering Details"

    table {
      width = 12
      query = query.network_express_route_peerings
      args  = [self.input.er_id.value]
    }
  }

  container {

    title = "Tag Details"

    table {
      width = 3
      query = query.network_express_route_tags
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

# table queries

query "network_express_route_tags" {
  sql = <<-EOQ
    select
      name,
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

query "network_express_route_peerings" {
  sql = <<-EOQ
    select
      name,
      replace(jsonb_path_query(peerings, '$.properties.azureASN')::text, '"', '') as "Azure ASN",
      replace(jsonb_path_query(peerings, '$.properties.connections')::text, '"', '') as "Connections",
      replace(jsonb_path_query(peerings, '$.properties.gatewayManagerEtag')::text, '"', '') as "Gateway Manager Etag",
      replace(jsonb_path_query(peerings, '$.properties.peerASN')::text, '"', '') as "Peer ASN",
      replace(jsonb_path_query(peerings, '$.properties.peeringType')::text, '"', '') as "Peering Type",
      replace(jsonb_path_query(peerings, '$.properties.primaryAzurePort')::text, '"', '') as "Primary Azure Port",
      replace(jsonb_path_query(peerings, '$.properties.primaryPeerAddressPrefix')::text, '"', '') as "Primary Peer Address Prefix",
      replace(jsonb_path_query(peerings, '$.properties.secondaryAzurePort')::text, '"', '') as "Secondary Azure Port",
      replace(jsonb_path_query(peerings, '$.properties.secondaryPeerAddressPrefix')::text, '"', '') as "Secondary Peer Address Prefix",
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

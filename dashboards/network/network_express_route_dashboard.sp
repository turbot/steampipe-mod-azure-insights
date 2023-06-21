dashboard "network_express_route_dashboard" {

  title         = "Azure Express Route Circuit Dashboard"
  documentation = file("./dashboards/network/docs/network_express_route_dashboard.md")

  tags = merge(local.network_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.express_route_circuit_count
      width = 3
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Express Route Circuits by Subscription"
      query = query.express_route_circuit_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Express Route Circuits by Region"
      query = query.express_route_circuit_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Express Route Circuits by Provisioning State"
      query = query.virtual_network_by_provisioning_state
      type  = "column"
      width = 3
    }

    chart {
      title = "Express Route Circuits by Sku Tier"
      query = query.express_route_circuit_by_sku_tier
      type  = "column"
      width = 3
    } 
  }

  container {

    table {
      title = "Service Provider Properties"
      width = 12
      query = query.network_express_route_service_provider_properties
    }
  }

}

# Card Queries

query "express_route_circuit_count" {
  sql = <<-EOQ
    select count(*) as ExpressRoutes from azure_express_route_circuit;
  EOQ
}

# Analysis Queries

query "express_route_circuit_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(n.*) as "Express Route Circuits"
    from
      azure_express_route_circuit as n,
      azure_subscription as sub
    where
      sub.subscription_id = n.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "express_route_circuit_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Express Route Circuits"
    from
      azure_express_route_circuit
    group by
      region
    order by
      region;
  EOQ
}

query "express_route_circuit_by_provisioning_state" {
  sql = <<-EOQ
    select
      provisioning_state as "Provisioning State",
      count(*) as "Express Route Circuits"
    from
      azure_express_route_circuit
    group by
      provisioning_state
    order by
      provisioning_state;
  EOQ
}

query "express_route_circuit_by_sku_tier" {
  sql = <<-EOQ
    select
      sku_tier as "Sku Tier",
      count(*) as "Express Route Circuits"
    from
      azure_express_route_circuit
    group by
      sku_tier
    order by
      sku_tier;
  EOQ
}

query "network_express_route_service_provider_properties" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      n.name as "Name",
      n.sku_tier as "Sku Tier",
      n.sku_family as "Sku Family",
      n.service_provider_properties -> 'peeringLocation' as "Peering Location",
      n.service_provider_properties -> 'bandwidthInMbps' as "Bandwidth In Mbps",
      n.service_provider_properties -> 'serviceProviderName' as "Service Provider Name"
    from
      azure_express_route_circuit as n,
      azure_subscription as sub
    order by
      name;
  EOQ
}

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

    card {
      query = query.express_route_circuit_no_peerings_count
      width = 3
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "With Peering"
      query = query.express_route_circuit_by_peerings
      type  = "donut"
      width = 3

      series "count" {
        point "with peering" {
          color = "ok"
        }
        point "no peering" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Express Route Circuits by Subscription"
      query = query.express_route_circuit_by_subscription
      type  = "column"
      width = 4
    }

    chart {
      title = "Express Route Circuits by Region"
      query = query.express_route_circuit_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Express Route Circuits by Sku Tier"
      query = query.express_route_circuit_by_sku_tier
      type  = "column"
      width = 4
    }

    chart {
      title = "Express Route Circuits by Provisioning State"
      query = query.express_route_circuit_by_provisioning_state
      type  = "column"
      width = 4
    }

    chart {
      title = "Express Route Circuits by Service Provider Provisioning State"
      query = query.express_route_circuit_by_service_provider_provisioning_state
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "express_route_circuit_count" {
  sql = <<-EOQ
    select count(*) as "Express Routes" from azure_express_route_circuit;
  EOQ
}

query "express_route_circuit_no_peerings_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'No Peerings' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      azure_express_route_circuit
    where
      jsonb_array_length(peerings) = 0
  EOQ
}

query "express_route_circuit_by_peerings" {
  sql = <<-EOQ
    select
      peering,
      count(*)
    from (
      select
        case when jsonb_array_length(peerings) = 0 then
          'no peering'
        else
          'with peering'
        end as peering
      from
        azure_express_route_circuit) as cd
    group by
      peering
    order by
      peering;
  EOQ
}

# Assessment Queries

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

query "express_route_circuit_by_service_provider_provisioning_state" {
  sql = <<-EOQ
    select
      service_provider_provisioning_state as "Service Provider Provisioning State",
      count(*) as "Express Route Circuits"
    from
      azure_express_route_circuit
    group by
      service_provider_provisioning_state
    order by
      service_provider_provisioning_state;
  EOQ
}
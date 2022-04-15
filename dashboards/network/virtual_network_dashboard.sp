dashboard "azure_virtual_network_dashboard" {

  title         = "Azure Virtual Network Dashboard"
  documentation = file("./dashboards/network/docs/virtual_network_dashboard.md")

  tags = merge(local.network_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.azure_virtual_network_count
      width = 2
    }

    card {
      query = query.azure_virtual_network_ddos_protection_enabled
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "DDoS Protection"
      query = query.azure_virtual_network_ddos_protection_status
      type  = "donut"
      width = 2

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Virtual Networks by Subscription"
      query = query.azure_virtual_network_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Virtual Networks by Resource Group"
      query = query.azure_virtual_network_by_resource_group
      type  = "column"
      width = 3
    }

    chart {
      title = "Virtual Networks by Region"
      query = query.azure_virtual_network_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Virtual Networks by Provisioning State"
      query = query.azure_virtual_network_by_provisioning_state
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "azure_virtual_network_count" {
  sql = <<-EOQ
    select count(*) as "Virtual Networks" from azure_virtual_network;
  EOQ
}

query "azure_virtual_network_ddos_protection_enabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'DDoS Protection Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_virtual_network
    where
      enable_ddos_protection is not true;
  EOQ
}

# Assessment Queries

query "azure_virtual_network_ddos_protection_status" {
  sql = <<-EOQ
    select
      ddos,
      count(*)
    from (
      select
        case when enable_ddos_protection then 'enabled'
        else 'disabled'
        end ddos
      from
        azure_virtual_network) as n
    group by
      ddos
    order by
      ddos;
  EOQ
}

# Analysis Queries

query "azure_virtual_network_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(n.*) as "Virtual Networks"
    from
      azure_virtual_network as n,
      azure_subscription as sub
    where
      sub.subscription_id = n.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "azure_virtual_network_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(n.*) as "Virtual Networks"
    from
      azure_virtual_network as n,
      azure_subscription as sub
    where
      n.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_virtual_network_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Virtual Networks"
    from
      azure_virtual_network
    group by
      region
    order by
      region;
  EOQ
}

query "azure_virtual_network_by_provisioning_state" {
  sql = <<-EOQ
    select
      provisioning_state as "Provisioning State",
      count(*) as "Virtual Networks"
    from
      azure_virtual_network
    group by
      provisioning_state
    order by
      provisioning_state;
  EOQ
}



dashboard "azure_network_security_group_dashboard" {

  title         = "Azure Network Security Group Dashboard"
  documentation = file("./dashboards/network/docs/network_security_group_dashboard.md")

  tags = merge(local.network_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.azure_network_security_group_count
      width = 2
    }

    card {
      query = query.azure_network_security_group_unassociated_count
      width = 2
    }

    card {
      query = query.azure_network_security_group_flow_logs_disabled_count
      width = 2
    }

    card {
      query = query.azure_network_security_group_unrestricted_ingress_count
      width = 2
    }

    card {
      query = query.azure_network_security_group_unrestricted_egress_count
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Association Status"
      query = query.azure_network_security_group_unused_status
      type  = "donut"
      width = 3

      series "count" {
        point "associated" {
          color = "ok"
        }
        point "unassociated" {
          color = "alert"
        }
      }
    }

    chart {
      title = "NSG Flow Logs"
      query = query.azure_network_security_group_flow_logs_status
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "With Unrestricted Ingress (Excludes ICMP)"
      query = query.azure_network_security_group_unrestricted_ingress

      type  = "donut"
      width = 3

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }


    chart {
      title = "With Unrestricted Egress (Excludes ICMP)"
      query = query.azure_network_security_group_unrestricted_egress

      type  = "donut"
      width = 3

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Network Security Groups by Subscription"
      query = query.azure_network_security_group_by_subscription
      type  = "column"
      width = 3
    }

    chart {
      title = "Network Security Groups by Resource Group"
      query = query.azure_network_security_group_by_resource_group
      type  = "column"
      width = 3
    }

    chart {
      title = "Network Security Groups by Region"
      query = query.azure_network_security_group_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Network Security Groups by Provisioning State"
      query = query.azure_network_security_group_by_provisioning_state
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "azure_network_security_group_count" {
  sql = <<-EOQ
    select count(*) as "Network Security Groups" from azure_network_security_group;
  EOQ
}

query "azure_network_security_group_unassociated_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unassociated' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_network_security_group
    where
      subnets is null and network_interfaces is null;
  EOQ
}

query "azure_network_security_group_flow_logs_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Flow Logs Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_network_security_group
    where
      flow_logs is null;
  EOQ
}

query "azure_network_security_group_unrestricted_ingress_count" {
  sql = <<-EOQ
    with network_sg as (
      select
        distinct name sg_name
      from
        azure_network_security_group nsg,
        jsonb_array_elements(security_rules) sg,
        jsonb_array_elements_text(sg -> 'properties' -> 'destinationPortRanges' || (sg -> 'properties' -> 'destinationPortRange') :: jsonb) dport,
        jsonb_array_elements_text(sg -> 'properties' -> 'sourceAddressPrefixes' || (sg -> 'properties' -> 'sourceAddressPrefix') :: jsonb) sip
      where
        sg -> 'properties' ->> 'access' = 'Allow'
        and sg -> 'properties' ->> 'direction' = 'Inbound'
        and sg -> 'properties' ->> 'protocol' <> 'ICMP'
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport = '*'
          or (
            dport like '%-%'
            and (
              split_part(dport, '-', 1) :: integer = 0
              and split_part(dport, '-', 2) :: integer = 65535
            )
          )
        )
    )
    select
      count(*) as value,
      'Unrestricted Ingress (Excludes ICMP)' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      network_sg

  EOQ
}

query "azure_network_security_group_unrestricted_egress_count" {
  sql = <<-EOQ
    with network_sg as (
      select
        distinct name sg_name
      from
        azure_network_security_group nsg,
        jsonb_array_elements(security_rules) sg,
        jsonb_array_elements_text(sg -> 'properties' -> 'destinationPortRanges' || (sg -> 'properties' -> 'destinationPortRange') :: jsonb) dport,
        jsonb_array_elements_text(sg -> 'properties' -> 'sourceAddressPrefixes' || (sg -> 'properties' -> 'sourceAddressPrefix') :: jsonb) sip
      where
        sg -> 'properties' ->> 'access' = 'Allow'
        and sg -> 'properties' ->> 'direction' = 'Outbound'
        and sg -> 'properties' ->> 'protocol' <> 'ICMP'
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport = '*'
          or (
            dport like '%-%'
            and (
              split_part(dport, '-', 1) :: integer = 0
              and split_part(dport, '-', 2) :: integer = 65535
            )
          )
        )
    )
    select
      count(*) as value,
      'Unrestricted Egress (Excludes ICMP)' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      network_sg

  EOQ
}

# Assessment Queries

query "azure_network_security_group_unused_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select
        case when (subnets is null and network_interfaces is null) then 'unassociated'
        else 'associated'
        end status
      from
        azure_network_security_group) as n
    group by
      status
    order by
      status;
  EOQ
}

query "azure_network_security_group_flow_logs_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select
        case when (flow_logs is null) then 'disabled'
        else 'enabled'
        end status
      from
        azure_network_security_group) as n
    group by
      status
    order by
      status;
  EOQ
}

query "azure_network_security_group_unrestricted_ingress" {
  sql = <<-EOQ
    with network_sg as (
      select
        distinct name sg_name
      from
        azure_network_security_group nsg,
        jsonb_array_elements(security_rules) sg,
        jsonb_array_elements_text(sg -> 'properties' -> 'destinationPortRanges' || (sg -> 'properties' -> 'destinationPortRange') :: jsonb) dport,
        jsonb_array_elements_text(sg -> 'properties' -> 'sourceAddressPrefixes' || (sg -> 'properties' -> 'sourceAddressPrefix') :: jsonb) sip
      where
        sg -> 'properties' ->> 'access' = 'Allow'
        and sg -> 'properties' ->> 'direction' = 'Inbound'
        and sg -> 'properties' ->> 'protocol' <> 'ICMP'
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport = '*'
          or (
            dport like '%-%'
            and (
              split_part(dport, '-', 1) :: integer = 0
              and split_part(dport, '-', 2) :: integer = 65535
            )
          )
        )
    )
    select
      case when name in (select sg_name from network_sg ) then 'unrestricted' else 'restricted' end as status,
      count(*)
  from
    azure_network_security_group
    group by
      status
    order by
      status;
  EOQ
}

query "azure_network_security_group_unrestricted_egress" {
  sql = <<-EOQ
    with network_sg as (
      select
        distinct name sg_name
      from
        azure_network_security_group nsg,
        jsonb_array_elements(security_rules) sg,
        jsonb_array_elements_text(sg -> 'properties' -> 'destinationPortRanges' || (sg -> 'properties' -> 'destinationPortRange') :: jsonb) dport,
        jsonb_array_elements_text(sg -> 'properties' -> 'sourceAddressPrefixes' || (sg -> 'properties' -> 'sourceAddressPrefix') :: jsonb) sip
      where
        sg -> 'properties' ->> 'access' = 'Allow'
        and sg -> 'properties' ->> 'direction' = 'Outbound'
        and sg -> 'properties' ->> 'protocol' <> 'ICMP'
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport = '*'
          or (
            dport like '%-%'
            and (
              split_part(dport, '-', 1) :: integer = 0
              and split_part(dport, '-', 2) :: integer = 65535
            )
          )
        )
    )
    select
      case when name in (select sg_name from network_sg ) then 'unrestricted' else 'restricted' end as status,
      count(*)
  from
    azure_network_security_group
    group by
      status
    order by
      status;
  EOQ
}

# Analysis Queries

query "azure_network_security_group_by_subscription" {
  sql = <<-EOQ
    select
      sub.title as "Subscription",
      count(n.*) as "Network Security Groups"
    from
      azure_network_security_group as n,
      azure_subscription as sub
    where
      sub.subscription_id = n.subscription_id
    group by
      sub.title
    order by
      sub.title;
  EOQ
}

query "azure_network_security_group_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group || ' [' || sub.title || ']' as "Resource Group",
      count(n.*) as "Network Security Groups"
    from
      azure_network_security_group as n,
      azure_subscription as sub
    where
      n.subscription_id = sub.subscription_id
    group by
      resource_group, sub.title
    order by
      resource_group;
  EOQ
}

query "azure_network_security_group_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Network Security Groups"
    from
      azure_network_security_group
    group by
      region
    order by
      region;
  EOQ
}

query "azure_network_security_group_by_provisioning_state" {
  sql = <<-EOQ
    select
      provisioning_state as "Provisioning State",
      count(*) as "Network Security Groups"
    from
      azure_network_security_group
    group by
      provisioning_state
    order by
      provisioning_state;
  EOQ
}
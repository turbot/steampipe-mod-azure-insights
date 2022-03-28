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
      query = query.azure_network_security_group_empty_subnets_count
      width = 2
    }

    card {
      query = query.azure_network_security_group_remote_access_inbound_count
      width = 2
    }

    card {
      query = query.azure_network_security_group_remote_access_outbound_count
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Network Security Groups With Empty Subnets"
      query = query.azure_network_security_group_empty_subnets_status
      type  = "donut"
      width = 3

      series "count" {
        point "non-empty" {
          color = "ok"
        }
        point "empty" {
          color = "alert"
        }
      }
    }


    chart {
      title = "With Unrestricted Inbound"
      query = query.azure_network_security_group_remote_access_inbound

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
      title = "With Unrestricted Outbound"
      query = query.azure_network_security_group_remote_access_outbound

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

query "azure_network_security_group_empty_subnets_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Empty Subnets' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      azure_network_security_group
    where
      subnets is null;
  EOQ
}

query "azure_network_security_group_remote_access_inbound_count" {
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
        and sg -> 'properties' ->> 'protocol' = 'TCP'
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport in ('22', '3389', '*')
          or (
            dport like '%-%'
            and (
              (
                split_part(dport, '-', 1) :: integer <= 3389
                and split_part(dport, '-', 2) :: integer >= 3389
              )
              or (
                split_part(dport, '-', 1) :: integer <= 22
                and split_part(dport, '-', 2) :: integer >= 22
              )
            )
          )
        )
    )
    select
      count(*) as value,
      'With Unrestricted Inbound' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      network_sg

  EOQ
}

query "azure_network_security_group_remote_access_outbound_count" {
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
        and sg -> 'properties' ->> 'protocol' = 'TCP'
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport in ('22', '3389', '*')
          or (
            dport like '%-%'
            and (
              (
                split_part(dport, '-', 1) :: integer <= 3389
                and split_part(dport, '-', 2) :: integer >= 3389
              )
              or (
                split_part(dport, '-', 1) :: integer <= 22
                and split_part(dport, '-', 2) :: integer >= 22
              )
            )
          )
        )
    )
    select
      count(*) as value,
      'With Unrestricted Outbound' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      network_sg

  EOQ
}

# Assessment Queries

query "azure_network_security_group_empty_subnets_status" {
  sql = <<-EOQ
    select
      status,
      count(*)
    from (
      select
        case when subnets is null then 'empty'
        else 'non-empty'
        end status
      from
        azure_network_security_group) as n
    group by
      status
    order by
      status;
  EOQ
}

query "azure_network_security_group_remote_access_inbound" {
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
        and sg -> 'properties' ->> 'protocol' = 'TCP'
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport in ('22', '3389', '*')
          or (
            dport like '%-%'
            and (
              (
                split_part(dport, '-', 1) :: integer <= 3389
                and split_part(dport, '-', 2) :: integer >= 3389
              )
              or (
                split_part(dport, '-', 1) :: integer <= 22
                and split_part(dport, '-', 2) :: integer >= 22
              )
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

query "azure_network_security_group_remote_access_outbound" {
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
        and sg -> 'properties' ->> 'protocol' = 'TCP'
        and sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
        and (
          dport in ('22', '3389', '*')
          or (
            dport like '%-%'
            and (
              (
                split_part(dport, '-', 1) :: integer <= 3389
                and split_part(dport, '-', 2) :: integer >= 3389
              )
              or (
                split_part(dport, '-', 1) :: integer <= 22
                and split_part(dport, '-', 2) :: integer >= 22
              )
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



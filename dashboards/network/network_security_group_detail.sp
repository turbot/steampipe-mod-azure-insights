dashboard "azure_network_security_group_detail" {

  title         = "Azure Network Security Group Detail"
  documentation = file("./dashboards/network/docs/network_security_group_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "nsg_id" {
    title = "Select a network security group:"
    query = query.azure_network_security_group_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_network_security_group_inbound_rules_count
      args  = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_security_group_outbound_rules_count
      args  = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_security_group_attached_enis_count
      args  = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_security_group_unrestricted_inbound_remote_access
      args = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_security_group_unrestricted_outbound_remote_access
      args = {
        id = self.input.nsg_id.value
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
        query = query.azure_network_security_group_overview
        args = {
          id = self.input.nsg_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_network_security_group_tags
        args = {
          id = self.input.nsg_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Flow Logs"
        query = query.azure_network_security_group_flow_logs
        args = {
          id = self.input.nsg_id.value
        }
      }

      # table {
      #   title = "Image"
      #   query = query.azure_compute_virtual_machine_image
      #   args = {
      #     id = self.input.nsg_id.value
      #   }
      # }
    }

  }

  container {

    width = 6

    table {
      title = "Inbound Rules"
      query = query.azure_network_security_group_inbound_rules
      args  = {
        id = self.input.nsg_id.value
      }
    }

  }

  container {

    width = 6

    table {
      title = "Outbound Rules"
      query = query.azure_network_security_group_outbound_rules
      args = {
        id = self.input.nsg_id.value
      }
    }

  }


  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.azure_network_security_group_network_interfaces
      args = {
        id = self.input.nsg_id.value
      }
    }

  }

}

query "azure_network_security_group_input" {
  sql = <<-EOQ
    select
      g.title as label,
      g.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', g.resource_group,
        'region', g.region
      ) as tags
    from
      azure_network_security_group as g,
      azure_subscription as s
    where
      g.subscription_id = s.subscription_id
    order by
      g.title;
  EOQ
}

query "azure_network_security_group_inbound_rules_count" {
  sql = <<-EOQ
    select
      'Inbound Rules' as label,
      count(*) as value
    from
      azure_network_security_group,
      jsonb_array_elements(security_rules || default_security_rules ) as rules
    where
      rules -> 'properties' ->> 'direction' = 'Inbound'
      and id = $1
  EOQ

  param "id" {}
}

query "azure_network_security_group_outbound_rules_count" {
  sql = <<-EOQ
    select
      'Outbound Rules' as label,
      count(*) as value
    from
      azure_network_security_group,
      jsonb_array_elements(security_rules || default_security_rules ) as rules
    where
      rules -> 'properties' ->> 'direction' = 'Outbound'
      and id = $1
  EOQ

  param "id" {}
}

query "azure_network_security_group_attached_enis_count" {
  sql = <<-EOQ
    select
      'Attached Netwrok Interfaces' as label,
      count(*) as value
    from
      azure_network_security_group,
      jsonb_array_elements(network_interfaces ) as nic
    where
      id = $1
  EOQ

  param "id" {}
}

query "azure_network_security_group_unrestricted_inbound_remote_access" {
  sql = <<-EOQ
    with unrestricted_inbound as (
      select
        name sg_name
      from
        azure_network_security_group nsg,
        jsonb_array_elements(security_rules || default_security_rules ) sg,
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
        and nsg.id = '/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/turbot_rg/providers/Microsoft.Network/networkSecurityGroups/tetetq-nsg'
    )
    select
      'Unrestricted Inbound' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      unrestricted_inbound
  EOQ

  param "id" {}
}

query "azure_network_security_group_unrestricted_outbound_remote_access" {
  sql = <<-EOQ
    with unrestricted_inbound as (
      select
        name sg_name
      from
        azure_network_security_group nsg,
        jsonb_array_elements(security_rules || default_security_rules) sg,
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
        and nsg.id = '/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/turbot_rg/providers/Microsoft.Network/networkSecurityGroups/tetetq-nsg'
    )
    select
      'Unrestricted Outbound' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      unrestricted_inbound
  EOQ

  param "id" {}
}

query "azure_network_security_group_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      type as "Type",
      etag as "ETag",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_network_security_group
    where
      id = $1
  EOQ

  param "id" {}
}

query "azure_network_security_group_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_network_security_group,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_network_security_group_network_interfaces" {
  sql = <<-EOQ
    select
      ni.name as "Network Interface Name",
      ni.enable_ip_forwarding as "Enable IP Forwarding",
      ni.mac_address as "MAC Address",
      i ->> 'id' as "Network Interface ID"
    from
      azure_network_security_group as nsg,
      jsonb_array_elements(network_interfaces) as i
      left join azure_network_interface as ni on ni.id = i ->> 'id'
    where
      nsg.id = $1;
  EOQ

  param "id" {}
}

query "azure_network_security_group_flow_logs" {
  sql = <<-EOQ
    with flow_logs as (
      select
        l ->> 'id' as id
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(flow_logs) as l
      where
        nsg.id = $1
    )
    select
      fl.name as "Flow Log Name",
      fl.network_watcher_name as "Network Watcher Name",
      fl.enabled as "Enabled",
      f.id as "Flow Log ID"
    from
      flow_logs as f left join azure_network_watcher_flow_log as fl on fl.id = f.id

  EOQ

  param "id" {}
}

query "azure_network_security_group_inbound_rules" {
  sql = <<-EOQ
    select
        sg -> 'properties' ->> 'access' as "Access",
        sg -> 'properties' ->> 'protocol' as "Protocol",
        sip as "Source Address Prefixes",
        dport as "Destination Port Range"
      from
        azure_network_security_group nsg,
        jsonb_array_elements(security_rules || default_security_rules) sg,
        jsonb_array_elements_text(sg -> 'properties' -> 'destinationPortRanges' || (sg -> 'properties' -> 'destinationPortRange') :: jsonb) dport,
        jsonb_array_elements_text(sg -> 'properties' -> 'sourceAddressPrefixes' || (sg -> 'properties' -> 'sourceAddressPrefix') :: jsonb) sip
      where
        sg -> 'properties' ->> 'direction' = 'Inbound'
        and nsg.id = $1;
  EOQ

  param "id" {}
}

query "azure_network_security_group_outbound_rules" {
  sql = <<-EOQ
    select
      sg -> 'properties' ->> 'access' as "Access",
      sg -> 'properties' ->> 'protocol' as "Protocol",
      sip as "Source Address Prefixes",
      dport as "Destination Port Range"
    from
      azure_network_security_group nsg,
      jsonb_array_elements(security_rules || default_security_rules) sg,
      jsonb_array_elements_text(sg -> 'properties' -> 'destinationPortRanges' || (sg -> 'properties' -> 'destinationPortRange') :: jsonb) dport,
      jsonb_array_elements_text(sg -> 'properties' -> 'sourceAddressPrefixes' || (sg -> 'properties' -> 'sourceAddressPrefix') :: jsonb) sip
    where
      sg -> 'properties' ->> 'direction' = 'Outbound'
      and nsg.id = $1;
  EOQ

  param "id" {}
}


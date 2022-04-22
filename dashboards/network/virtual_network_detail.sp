dashboard "azure_virtual_network_detail" {

  title         = "Azure Virtual Network Detail"
  documentation = file("./dashboards/network/docs/virtual_network_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "vn_id" {
    title = "Select a virtual network:"
    query = query.azure_virtual_network_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_virtual_network_num_ips
      args = {
        id = self.input.vn_id.value
      }
    }

    card {
      width = 2
      query = query.azure_virtual_network_subnets_count
      args = {
        id = self.input.vn_id.value
      }
    }

    card {
      width = 2
      query = query.azure_virtual_network_ddos_protection
      args = {
        id = self.input.vn_id.value
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
        query = query.azure_virtual_network_overview
        args = {
          id = self.input.vn_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_virtual_network_tags
        args = {
          id = self.input.vn_id.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Address Prefixes"
        query = query.azure_virtual_network_address_prefixes
        args  = {
          id = self.input.vn_id.value
        }
      }

    }

  }

  container {

    table {
      title = "Subnets"
      query = query.azure_virtual_network_subnet_details
      args  = {
        id = self.input.vn_id.value
      }
    }
  }


  container {

    table {
      title = "Network Security Groups"
      query = query.azure_virtual_network_nsg
      args = {
        id = self.input.vn_id.value
      }
    }

    flow {
      title = "NSG Associated Subnet Ingress Analysis"
      width = 6
      base = flow.nsg_flow
      query = query.azure_virtual_network_ingress_rule_sankey
      args = {
        id = self.input.vn_id.value
      }
    }

    flow {
      title = "NSG Associated Subnet Egress Analysis"
      base = flow.nsg_flow
      width = 6
      query = query.azure_virtual_network_egress_rule_sankey
      args = {
        id = self.input.vn_id.value
      }
    }

  }

  container {

    title = "Routing"

    table {
      title = "Route Tables"
      query = query.azure_virtual_network_route_tables
      width = 6
      args = {
        id = self.input.vn_id.value
      }
    }

    table {
      title = "Routes"
      query = query.azure_virtual_network_routes
      width = 6
      args = {
        id = self.input.vn_id.value
      }
    }

  }

  table {
    title = "Peering Connections"
    query = query.azure_virtual_network_peering_connection
    args = {
      id = self.input.vn_id.value
    }
  }

}

flow "nsg_flow" {
  width = 6
  type  = "sankey"


  category "Deny" {
    color = "alert"
  }

  category "Allow" {
    color = "ok"
  }

}

query "azure_virtual_network_input" {
  sql = <<-EOQ
    select
      n.title as label,
      n.id as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', n.resource_group,
        'region', n.region
      ) as tags
    from
      azure_virtual_network as n,
      azure_subscription as s
    where
      n.subscription_id = s.subscription_id
    order by
      n.title;
  EOQ
}

query "azure_virtual_network_subnets_count" {
  sql = <<-EOQ
    select
      'Subnets' as label,
      jsonb_array_length(subnets) as value
    from
      azure_virtual_network
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_virtual_network_ddos_protection" {
  sql = <<-EOQ
    select
      'DDoS Protection' as label,
      case when enable_ddos_protection then 'Enabled' else 'Disabled' end as value,
      case when enable_ddos_protection then 'ok' else 'alert' end as type
    from
      azure_virtual_network
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_virtual_network_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      provisioning_state as "Provisioning State",
      cloud_environment as "Cloud Environment",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_virtual_network
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_virtual_network_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_virtual_network,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_virtual_network_subnet_details" {
  sql = <<-EOQ
    select
      s ->> 'name' as "Name",
      s -> 'properties' ->> 'addressPrefix' as "Address Prefix",
      power(2, 32 - masklen((s -> 'properties' ->> 'addressPrefix'):: cidr)) -1 as "Total IPs",
      s -> 'properties' ->> 'privateEndpointNetworkPolicies' as "Private Endpoint Network Policies",
      s -> 'properties' ->> 'privateLinkServiceNetworkPolicies' as "Private Link Service Network Policies",
      s ->> 'id' as "Subnet ID"
    from
      azure_virtual_network,
      jsonb_array_elements(subnets) as s
  where
    id = $1
  EOQ

  param "id" {}
}

query "azure_virtual_network_ingress_rule_sankey" {
  sql = <<-EOQ
  with subnets as (
    select
      s ->> 'name' as "subnet_name",
      s -> 'properties' ->>  'addressPrefix' as  addressPrefix,
      s ->> 'id' as "subnet_id",
      s -> 'properties' -> 'networkSecurityGroup' ->> 'id' as "networkSecurityGroup",
      name as vnet_name
    from
      azure_virtual_network,
      jsonb_array_elements(subnets) as s
      where id = $1
  ),network_security_group as (
      select
        id,
        default_security_rules,
        security_rules,
        s
      from
      azure_network_security_group as sg,
      jsonb_array_elements(subnets) as s
  ),
  network_security_group_rule as (
    select
      network_security_group.id as nsgid,
      (default_security_rules || security_rules) as all_rules,
      subnets.subnet_id as "subnet_id",
      subnets.subnet_name as "subnet_name",
      subnets.addressPrefix as addressPrefix,
      subnets.vnet_name as vnet_name
    from
    subnets left join network_security_group on network_security_group.s ->> 'id' = subnets.subnet_id
  ),
  data as (
    select
      subnet_name,
      subnet_id,
      nsgid,
      vnet_name,
      addressPrefix,
      sip as cidr_block,
      r -> 'properties' -> 'priority' as rule_priority,
      r ->> 'name' as rule_name,
      r -> 'properties' ->> 'access' as rule_action,
      case when r -> 'properties' ->> 'access' = 'Allow' then 'Allow ' else 'Deny ' end ||
      case
        when (r -> 'properties' ->> 'protocol' = '*') then 'All Traffic'
        when (r -> 'properties' ->> 'protocol' = 'ICMP') then 'All ICMP'
        when (r -> 'properties' ->> 'protocol' = 'UDP') then 'All UDP'
        when (r -> 'properties' ->> 'protocol' = 'TCP')
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
        ) then 'All TCP'
        else concat('Procotol: ', r -> 'properties' ->> 'protocol')
      end as rule_description
      from network_security_group_rule,
    jsonb_array_elements(all_rules) as r,
    jsonb_array_elements_text(r -> 'properties' -> 'sourceAddressPrefixes' || (r -> 'properties' -> 'sourceAddressPrefix') :: jsonb) as sip,
    jsonb_array_elements_text(r -> 'properties' -> 'destinationPortRanges' || (r -> 'properties' -> 'destinationPortRange') :: jsonb) dport
    where r -> 'properties' ->> 'direction' = 'Inbound'
  )

    -- CIDR Nodes
    select
      distinct cidr_block as id,
      cidr_block as title,
      'cidr_block' as category,
      null as from_id,
      null as to_id
    from data

    -- Rule Nodes
    union select
      concat(trim((split_part(nsgid, '/', 9)), '""'), '_', rule_name) as id,
      concat(rule_priority, ': ', rule_description) as title,
      'rule' as category,
      null as from_id,
      null as to_id
    from data

    -- NSG Nodes
    union select
      distinct concat ( trim((split_part(nsgid, '/', 9)), '""')) as id,
      concat (trim((split_part(nsgid, '/', 9)), '""')) as title,
      'nsg' as category,
      null as from_id,
      null as to_id
    from data

    -- Subnet Nodes
    union select
      distinct split_part(subnet_id, '/', 10) || '/' || trim((split_part(subnet_id, '/', 11)), '""') as id,
      split_part(subnet_id, '/', 10) || '/' || trim((split_part(subnet_id, '/', 11)), '""')  as title,
      'subnet' as category,
      null as from_id,
      null as to_id
    from data

     -- ip -> rule edge
    union select
      null as id,
      null as title,
      rule_action as category,
      cidr_block as from_id,
      concat(trim((split_part(nsgid, '/', 9)), '""'), '_', rule_name)  as to_id
    from data

    -- rule -> NSG edge
    union select
      null as id,
      null as title,
      rule_action as category,
      concat( trim((split_part(nsgid, '/', 9)), '""'), '_', rule_name) as from_id,
      concat ( trim((split_part(nsgid, '/', 9)), '""'))  as to_id
    from data

    -- nsg -> subnet edge
    union select
      null as id,
      null as title,
      'attached' as category,
      concat ( trim((split_part(nsgid, '/', 9)), '""')) as from_id,
      split_part(subnet_id, '/', 10) || '/' || trim((split_part(subnet_id, '/', 11)), '""') as to_id
    from data

  EOQ

  param "id" {}
}

query "azure_virtual_network_egress_rule_sankey" {

  sql = <<-EOQ
    with subnets as (
      select
        s -> 'name' as "subnet_name",
        s -> 'properties' ->>  'addressPrefix' as  addressPrefix,
        s ->> 'id' as "subnet_id",
        s -> 'properties' -> 'networkSecurityGroup' ->> 'id' as "networkSecurityGroup"
        from
        azure_virtual_network,
        jsonb_array_elements(subnets) as s
        where id = $1
    ),network_security_group as (
        select
          id,
          default_security_rules,
          security_rules,
          s
        from
        azure_network_security_group as sg,
        jsonb_array_elements(subnets) as s
    ),
    network_security_group_rule as (
      select
        network_security_group.id as "nsgid",
        (default_security_rules || security_rules) as all_rules,
        subnets.subnet_id as "subnet_id",
        subnets.subnet_name as "subnet_name",
        subnets.addressPrefix as addressPrefix
      from
        subnets left join network_security_group on network_security_group.s ->> 'id' = subnets.subnet_id
    ),
    data as (
      select
        subnet_name::text,
        subnet_id,
        nsgid,
        addressPrefix,
        sip as cidr_block,
        r -> 'properties' -> 'priority' as rule_priority,
        r ->> 'name' as rule_name,
        r -> 'properties' ->> 'access' as rule_action,
        to_char((r -> 'properties' -> 'priority')::numeric, 'fm00000')  as priority_padded,
        case when r -> 'properties' ->> 'access' = 'Allow' then 'Allow ' else 'Deny ' end ||
        case
          when (r -> 'properties' ->> 'protocol' = '*') then 'All Traffic'
          when (r -> 'properties' ->> 'protocol' = 'UDP') then 'All UDP'
          when (r -> 'properties' ->> 'protocol' = 'ICMP') then 'All ICMP'
          when (r -> 'properties' ->> 'protocol' = 'TCP')
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
            ) then 'All TCP'

          else concat('Procotol: ', r -> 'properties' ->> 'protocol')
        end as rule_description
        from network_security_group_rule,
      jsonb_array_elements(all_rules) as r,
      jsonb_array_elements_text(r -> 'properties' -> 'sourceAddressPrefixes' || (r -> 'properties' -> 'sourceAddressPrefix') :: jsonb) as sip,
      jsonb_array_elements_text(r -> 'properties' -> 'destinationPortRanges' || (r -> 'properties' -> 'destinationPortRange') :: jsonb) dport
      where r -> 'properties' ->> 'direction' = 'Outbound'
    )

  -- Subnet Nodes
    select
      distinct split_part(subnet_id, '/', 10) || '/' || trim((split_part(subnet_id, '/', 11)), '""') as id,
      split_part(subnet_id, '/', 10) || '/' || trim((split_part(subnet_id, '/', 11)), '""') as title,
      'vswitch' as category,
      null as from_id,
      null as to_id,
      0 as depth
    from data

    -- ACL Nodes
    union select
      distinct trim((split_part(nsgid, '/', 9)), '""') as id,
      concat (trim((split_part(nsgid, '/', 9)), '""')) as title,
      'nsg' as category,
      null as from_id,
      null as to_id,
      1 as depth
    from data

    -- Rule Nodes
    union select
      concat( trim((split_part(nsgid, '/', 9)), '""'), '_', rule_name)  as id,
      concat(rule_priority, ': ', rule_description) as title,
      'rule' as category,
      null as from_id,
      null as to_id,
      2 as depth
    from data

    -- CIDR Nodes
    union select
      distinct cidr_block as id,
      cidr_block as title,
      'cidr_block' as category,
      null as from_id,
      null as to_id,
      3 as depth
    from data

    -- nsg -> subnet edge
    union select
      null as id,
      null as title,
      'attached' as category,
      concat (trim((split_part(nsgid, '/', 9)), '""')) as from_id,
      split_part(subnet_id, '/', 10) || '/' || trim((split_part(subnet_id, '/', 11)), '""') as to_id,
      null as depth
    from data

    -- rule -> NSG edge
    union select
      null as id,
      null as title,
      rule_action as category,
      concat(trim((split_part(nsgid, '/', 9)), '""'), '_', rule_name)  as from_id,
      concat ( trim((split_part(nsgid, '/', 9)), '""')) as to_id,
      null as depth
    from data

    -- ip -> rule edge
    union select
      null as id,
      null as title,
      rule_action as category,
      cidr_block as from_id,
      concat(trim((split_part(nsgid, '/', 9)), '""'), '_', rule_name)  as to_id,
      null as depth
    from data
  EOQ

  param "id" {}
}

query "azure_virtual_network_num_ips" {
  sql = <<-EOQ
    with cidrs as (
      select
      masklen((trim('"' FROM a::text))::cidr)  as "Mask Length",
       power(2, 32 - masklen( (trim('"' FROM a::text) ):: cidr)) as num_ips
      from
        azure_virtual_network,
        jsonb_array_elements(address_prefixes) as a
      where id = $1
    )
    select
      sum(num_ips) as "IP Addresses"
    from
      cidrs;
  EOQ

  param "id" {}
}

query "azure_virtual_network_route_tables" {
  sql = <<-EOQ
    with route_table as (
      select
        distinct (s -> 'properties' -> 'routeTable' ->> 'id')  as id
      from
        azure_virtual_network,
        jsonb_array_elements(subnets) as s
      where
        id = $1
        and (s -> 'properties' -> 'routeTable' ->> 'id') is not null
      order by
        s -> 'properties' -> 'routeTable' ->> 'id'
    )
    select
      rt.name as "Name",
      rt.provisioning_state as "Provisioning State",
      r.id as "Route Table ID"
    from
      route_table as r left join azure_route_table as rt on rt.id = r.id
  EOQ

  param "id" {}
}

query "azure_virtual_network_routes" {
  sql = <<-EOQ

  with route_tables as (
    select
      distinct (s -> 'properties' -> 'routeTable' ->> 'id')  as id
    from
      azure_virtual_network,
      jsonb_array_elements(subnets) as s
    where
      id = $1
  ),
   data as (
    select
      *
    from
      route_tables as t left join azure_route_table as rt on t.id = rt.id
  ) select
      r ->> 'name' as "Name",
      r -> 'properties' ->> 'addressPrefix' as  "Address Prefix",
      r -> 'properties' ->> 'nextHopType' as  "Next Hop Type",
      r ->> 'id' as  "Route ID"
    from
      data,
      jsonb_array_elements(routes) as r;
  EOQ

  param "id" {}
}

query "azure_virtual_network_nsg" {
  sql = <<-EOQ
    with all_nsg as (
      select
        (s ->> 'name') as subnet_name,
        (s ->> 'id') as subnet_id,
        (s -> 'properties' -> 'networkSecurityGroup' ->> 'id') as nsg_id
      from
        azure_virtual_network,
        jsonb_array_elements(subnets) as s
      where
      (s -> 'properties' -> 'networkSecurityGroup' -> 'id') is not null
      and id = $1
    )
    select
      nsg.name as "Name",
      n.subnet_name as "Subnet Name",
      provisioning_state as "Provisioning State",
      nsg_id as "Network Security Group ID",
      n.subnet_id as "Subnet ID"
    from
      all_nsg as n left join azure_network_security_group as nsg on nsg.id = n.nsg_id
  EOQ

  param "id" {}
}

query "azure_virtual_network_peering_connection" {
  sql = <<-EOQ
    select
      np ->> 'name' as "Name",
      np -> 'properties' -> 'allowForwardedTraffic' as "Allow Forwarded Traffic",
      np -> 'properties' -> 'allowGatewayTransit' as "Allow Gateway Transit",
      np -> 'properties' -> 'allowVirtualNetworkAccess' as "Allow Virtual Network Access",
      np -> 'properties' -> 'peeringState' as "Peering State",
      np -> 'properties' -> 'remoteAddressSpace'  -> 'addressPrefixes' as "Address Prefixes",
      np -> 'properties' -> 'remoteVirtualNetwork' ->> 'id' as "Remote Virtual Network ID",
      np -> 'properties' -> 'useRemoteGateways'   as "Use Remote Gateways",
      np -> 'id' as "ID"
    from
      azure_virtual_network,
      jsonb_array_elements(network_peerings) as np
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_virtual_network_address_prefixes" {
  sql = <<-EOQ
    select
      (trim('"' FROM p::text))::cidr as "Address Prefix",
      power(2, 32 - masklen( (trim('"' FROM p::text) ):: cidr)) as "Total IPs"
    from
      azure_virtual_network,
      jsonb_array_elements(address_prefixes) as p
    where
      id = $1
  EOQ

  param "id" {}
}

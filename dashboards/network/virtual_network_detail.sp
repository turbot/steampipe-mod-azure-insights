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

    title = "Subnets"

    flow {
      query = query.azure_virtual_network_subnet_sankey
      args = {
        id = self.input.vn_id.value
      }
    }

    table {
      title = "Subnet Details"
      query = query.azure_virtual_network_subnet_details
      args  = {
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

  container {

    title = "Outbound Rules"

    flow {
      base = flow.nsg_flow
      width = 12
      query = query.azure_virtual_network_outbound_rule_sankey
      args = {
        id = self.input.vn_id.value
      }
    }

  }

  container {

    title = "Inbound Rules"

    flow {
      width = 12
      base = flow.nsg_flow
      query = query.azure_virtual_network_inbound_rule_sankey
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

  table {
    title = "Network Security Groups"
    query = query.azure_virtual_network_nsg
    args = {
      id = self.input.vn_id.value
    }
  }

}

flow "nsg_flow" {
  width = 6
  type  = "sankey"


  category "deny" {
    color = "alert"
  }

  category "allow" {
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
      'DDOS Protection' as label,
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

query "azure_virtual_network_subnet_sankey" {
  sql = <<-EOQ

  with subnets as (
    select
      s ->> 'name' as "subnet_name",
      s ->>'id' as "subnetid",
      case
        when s -> 'properties'-> 'natGateway' is not null then s -> 'properties'-> 'natGateway' ->> 'id'
      end as natGateway,
        case
        when s -> 'properties'-> 'addressPrefix' is not null then s -> 'properties'->> 'addressPrefix'
      end as addressPrefix
     from
      azure_virtual_network,
      jsonb_array_elements(subnets) as s
    where
      id = $1
  )
      select
        null as from_id,
        subnet_name as id,
        subnet_name as title,
        'azure_subnet' as category,
        0 as depth
      from
        subnets
      union
        select
          subnet_name as from_id,
          addressPrefix as id,
          addressPrefix as title,
          'addressPrefix' as category,
          1 as depth
        from
          subnets
      union
        select
          addressPrefix as from_id,
          natGateway as  id,
          split_part(natGateway, '/', 8) || '/' || trim((split_part(natGateway, '/', 9)), '""') as title,
          'natGateway' as category,
          2 as depth
        from
          subnets
  EOQ

  param "id" {}
}

query "azure_virtual_network_subnet_details" {
  sql = <<-EOQ
    select
      s ->> 'name' as "Name",
      s -> 'properties' ->> 'addressPrefix' as "addressPrefix",
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

query "azure_virtual_network_outbound_rule_sankey" {

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
        case when r -> 'properties' ->> 'access' = 'Allow' then 'Allow ' else 'Deny ' end ||
        case
          when (r -> 'properties' ->> 'protocol' = '*') then 'All Traffic'
          when (r -> 'properties' ->> 'protocol' = 'TCP') then 'All TCP'
          when (r -> 'properties' ->> 'protocol' = 'UDP') then 'All UDP'
          when (r -> 'properties' ->> 'protocol' = 'ICMP') then 'All ICMP'
          else concat('Procotol: ', r -> 'properties' ->> 'protocol')
        end as rule_description
        from network_security_group_rule,
      jsonb_array_elements(all_rules) as r,
      jsonb_array_elements_text(r -> 'properties' -> 'sourceAddressPrefixes' || (r -> 'properties' -> 'sourceAddressPrefix') :: jsonb) as sip
      where r -> 'properties' ->> 'direction' = 'Outbound'
    )
      -- Subnet Nodes
      select
        distinct subnet_id  as id,
        split_part(subnet_id, '/', 10) || '/' || trim((split_part(subnet_id, '/', 11)), '""') as title,
        'subnet' as category,
        null as from_id,
        null as to_id,
        0 as depth
      from data

      -- CIDR Nodes
      union select
        distinct addressPrefix as id,
        addressPrefix as title,
        'cidr_block' as category,
        subnet_id as from_id,
        null as to_id,
        1 as depth
      from data

        -- NSG Nodes
      union select
        distinct nsgid as id,
        split_part(nsgid, '/', 8) || '/' || trim((split_part(nsgid, '/', 9)), '""') as title,
        'nsgid' as category,
        addressPrefix as from_id,
        null as to_id,
        2 as depth
      from data

        -- Rule Nodes
      union select
        rule_description as id,
        rule_description as title,
        'rule' as category,
        nsgid as from_id,
        null as to_id,
        3 as depth
      from data
  EOQ

  param "id" {}
}

query "azure_virtual_network_inbound_rule_sankey" {
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
    subnets  left join network_security_group on network_security_group.s ->> 'id' = subnets.subnet_id
  ), --select * from network_security_group_rule
  data as (
    select
      subnet_name::text,
      subnet_id,
      nsgid,
      addressPrefix,
      case when r -> 'properties' ->> 'access' = 'Allow' then 'Allow ' else 'Deny ' end ||
      case
        when (r -> 'properties' ->> 'protocol' = '*') then 'All Traffic'
        when (r -> 'properties' ->> 'protocol' = 'TCP') then 'All TCP'
        when (r -> 'properties' ->> 'protocol' = 'UDP') then 'All UDP'
        when (r -> 'properties' ->> 'protocol' = 'ICMP') then 'All ICMP'
        else concat('Procotol: ', r -> 'properties' ->> 'protocol')
      end as rule_description
      from network_security_group_rule,
    jsonb_array_elements(all_rules) as r,
    jsonb_array_elements_text(r -> 'properties' -> 'sourceAddressPrefixes' || (r -> 'properties' -> 'sourceAddressPrefix') :: jsonb) as sip
    where r -> 'properties' ->> 'direction' = 'Inbound'
  )
    -- Subnet Nodes
    select
      distinct subnet_id  as id,
     split_part(subnet_id, '/', 10) || '/' || trim((split_part(subnet_id, '/', 11)), '""')  as title,
      'subnet' as category,
      null as from_id,
      null as to_id,
      0 as depth
    from data


    -- CIDR Nodes
    union select
      distinct addressPrefix as id,
      addressPrefix as title,
      'cidr_block' as category,
      subnet_id as from_id,
      null as to_id,
      1 as depth
    from data

        -- NSG Nodes
    union select
      distinct nsgid as id,
      split_part(nsgid, '/', 8) || '/' || trim((split_part(nsgid, '/', 9)), '""') as title,
      'nsgid' as category,
      addressPrefix as from_id,
      null as to_id,
      2 as depth
    from data

      -- Rule Nodes
    union select
      rule_description as id,
      rule_description as title,
      'rule' as category,
      nsgid as from_id,
      null as to_id,
       3 as depth
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
        id = '/subscriptions/d46d7416-f95f-4771-bbb5-529d4c76659c/resourceGroups/steampipe/providers/Microsoft.Network/virtualNetworks/steampipe-vnet'
      order by
        s -> 'properties' -> 'routeTable' ->> 'id'
    )
    select
      rt.name as "Route Table Name",
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
        distinct (s -> 'properties' -> 'networkSecurityGroup' ->> 'id') as nsg_id
      from
        azure_virtual_network,
        jsonb_array_elements(subnets) as s
      where
      (s -> 'properties' -> 'networkSecurityGroup' -> 'id') is not null
      and  id = $1
    )
    select
      nsg.name as "Network Security Group Name",
      nsg_id as "Network Security Group ID",
      provisioning_state as "Provisioning State"
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

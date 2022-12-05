dashboard "network_security_group_detail" {

  title         = "Azure Network Security Group Detail"
  documentation = file("./dashboards/network/docs/network_security_group_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "nsg_id" {
    title = "Select a network security group:"
    query = query.network_security_group_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.network_security_group_ingress_rules_count
      args = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.network_security_group_egress_rules_count
      args = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.network_security_group_attached_enis_count
      args = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.network_security_group_attached_subnets_count
      args = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.network_security_group_unrestricted_ingress_remote_access
      args = {
        id = self.input.nsg_id.value
      }
    }

    card {
      width = 2
      query = query.network_security_group_unrestricted_egress_remote_access
      args = {
        id = self.input.nsg_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "network_interfaces" {
        sql = <<-EOQ
          select
            lower(nic.id) as nic_id
          from
            azure_network_security_group as nsg,
            jsonb_array_elements(network_interfaces) as ni
            left join azure_network_interface as nic on lower(nic.id) = lower(ni ->> 'id')
          where
            (nic.id) is not null
            and lower(nsg.id) = $1;
          EOQ

        args = [self.input.nsg_id.value]
      }

      with "subnets" {
        sql = <<-EOQ
          select
            lower(s.id) as subnet_id
          from
            azure_network_security_group as nsg,
            jsonb_array_elements(subnets) as sub
            left join azure_subnet as s on lower(s.id) = lower(sub ->> 'id')
          where
            lower(nsg.id) = $1;
          EOQ

        args = [self.input.nsg_id.value]
      }

      with "virtual_networks" {
        sql = <<-EOQ
          with subnet_list as (
            select
              nsg.id as nsg_id,
              sub ->> 'id' as subnet_id
            from
              azure_network_security_group as nsg,
              jsonb_array_elements(subnets) as sub
            where
              lower(nsg.id) = $1
          ) select
              lower(vn.id) as network_id
            from
              azure_virtual_network as vn,
              jsonb_array_elements(subnets) as sub
              join subnet_list as s on lower(s.subnet_id) = lower(sub ->> 'id')
            where
              lower(s.nsg_id) = $1;
          EOQ

        args = [self.input.nsg_id.value]
      }

      with "virtual_machines" {
        sql = <<-EOQ
          with network_interface_list as (
            select
              nsg.id as nsg_id,
              nic.id as nic_id
            from
              azure_network_security_group as nsg,
              jsonb_array_elements(network_interfaces) as ni
              left join azure_network_interface as nic on lower(nic.id) = lower(ni ->> 'id')
            where
              lower(nsg.id )= $1
          )
          select
            lower(vm.id) as machine_id
          from
            azure_compute_virtual_machine as vm,
            jsonb_array_elements(network_interfaces) as ni
            left join network_interface_list as nic on lower(nic.nic_id) = lower(ni ->> 'id')
          where
            lower(nic.nsg_id) = $1;
          EOQ

        args = [self.input.nsg_id.value]
      }

      nodes = [
        node.compute_virtual_machine,
        node.network_network_interface,
        node.network_network_security_group,
        node.network_security_group_network_watcher_flow_log,
        node.network_subnet,
        node.network_virtual_network,
      ]

      edges = [
        edge.network_security_group_to_compute_virtual_machine,
        edge.network_security_group_to_network_interface,
        edge.network_security_group_to_network_watcher_flow_log,
        edge.network_subnet_to_network_security_group,
        edge.network_virtual_network_to_network_subnet,
      ]

      args = {
        compute_virtual_machine_ids = with.virtual_machines.rows[*].machine_id
        network_interface_ids       = with.network_interfaces.rows[*].nic_id
        network_security_group_ids  = [self.input.nsg_id.value]
        network_subnet_ids          = with.subnets.rows[*].subnet_id
        virtual_network_ids         = with.virtual_networks.rows[*].network_id
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
        query = query.network_security_group_overview
        args = {
          id = self.input.nsg_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.network_security_group_tags
        args = {
          id = self.input.nsg_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Associated to"
        query = query.network_security_group_assoc
        args = {
          id = self.input.nsg_id.value
        }
      }

      table {
        title = "Flow Logs"
        query = query.security_group_flow_logs
        args = {
          id = self.input.nsg_id.value
        }
      }

    }

  }

  container {

    width = 6

    flow {
      base  = flow.network_security_group_rules_sankey
      title = "Ingress Analysis"
      query = query.network_security_group_ingress_rule_sankey
      args = {
        id = self.input.nsg_id.value
      }
    }


    table {
      title = "Ingress Rules"
      query = query.network_security_group_ingress_rules
      args = {
        id = self.input.nsg_id.value
      }
    }

  }

  container {

    width = 6

    flow {
      base  = flow.network_security_group_rules_sankey
      title = "Egress Analysis"
      query = query.network_security_group_egress_rule_sankey
      args = {
        id = self.input.nsg_id.value
      }
    }

    table {
      title = "Egress Rules"
      query = query.network_security_group_egress_rules
      args = {
        id = self.input.nsg_id.value
      }
    }

  }

}

flow "network_security_group_rules_sankey" {
  type = "sankey"

  category "alert" {
    color = "alert"
  }

  category "ok" {
    color = "ok"
  }

}

query "network_security_group_input" {
  sql = <<-EOQ
    select
      g.title as label,
      lower(g.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'resource_group', g.resource_group,
        'region', g.region
      ) as tags
    from
      azure_network_security_group as g,
      azure_subscription as s
    where
      lower(g.subscription_id) = lower(s.subscription_id)
    order by
      g.title;
  EOQ
}

query "network_security_group_ingress_rules_count" {
  sql = <<-EOQ
    select
      'Ingress Rules' as label,
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

query "network_security_group_egress_rules_count" {
  sql = <<-EOQ
    select
      'Egress Rules' as label,
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

query "network_security_group_attached_enis_count" {
  sql = <<-EOQ
    select
      'Attached Network Interfaces' as label,
      count(*) as value
    from
      azure_network_security_group,
      jsonb_array_elements(network_interfaces ) as nic
    where
      id = $1
  EOQ

  param "id" {}
}

query "network_security_group_attached_subnets_count" {
  sql = <<-EOQ
    select
      'Attached Subnets' as label,
      count(*) as value
    from
      azure_network_security_group,
      jsonb_array_elements(subnets) as s
    where
      id = $1
  EOQ

  param "id" {}
}

query "network_security_group_unrestricted_ingress_remote_access" {
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
        and nsg.id = $1
    )
    select
      'Unrestricted Ingress (Excludes ICMP)' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      unrestricted_inbound
  EOQ

  param "id" {}
}

query "network_security_group_unrestricted_egress_remote_access" {
  sql = <<-EOQ
    with unrestricted_outbound as (
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
        and nsg.id = $1
    )
    select
      'Unrestricted Egress (Excludes ICMP)' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      unrestricted_outbound
  EOQ

  param "id" {}
}

query "network_security_group_overview" {
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

query "network_security_group_tags" {
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

query "network_security_group_assoc" {
  sql = <<-EOQ
    -- NICs
    select
      ni.title as "Title",
      'Network Interface' as "Type",
      ni.id as "ID"
     from
       azure_network_security_group as nsg,
       jsonb_array_elements(nsg.network_interfaces) as nic
       left join azure_network_interface as ni on lower(ni.id) = lower(nic ->> 'id')
     where
      nsg.id = $1

      -- Subnets
    union select
      s.title as "Title",
      'Subnet' as "Type",
      S.id as "ID"
     from
       azure_network_security_group as nsg,
       jsonb_array_elements(nsg.subnets) as subnets
       left join azure_subnet as s on lower(s.id) = lower(subnets ->> 'id')
     where
      nsg.id = $1
    EOQ

  param "id" {}
}

query "security_group_flow_logs" {
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
      fl.name as "Name",
      fl.network_watcher_name as "Network Watcher Name",
      fl.enabled as "Enabled",
      f.id as "Flow Log ID"
    from
      flow_logs as f left join azure_network_watcher_flow_log as fl on lower(fl.id) = lower(f.id)
    order by
      fl.name;

  EOQ

  param "id" {}
}

query "network_security_group_ingress_rules" {
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

query "network_security_group_egress_rules" {
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

query "network_security_group_ingress_rule_sankey" {
  sql = <<-EOQ

    with associations as (

      -- NICs
      select
        ni.title as title,
        'nsg' as category,
        ni.id as id,
        nsg.id as nsg_id
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(nsg.network_interfaces) as nic
        left join azure_network_interface as ni on lower(ni.id) = lower(nic ->> 'id')
      where
        nsg.id = $1

      -- Subnets
      union select
        s.title as title,
        'subnet' as category,
        s.id as id,
        nsg.id as nsg_id
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(nsg.subnets) as subnets
        left join azure_subnet as s on lower(s.id) = lower(subnets ->> 'id')
      where
        nsg.id = $1
      ),
      rules as (
        select
          sip as cidr_block,
          id,
          case
            when (r -> 'properties' ->> 'protocol' = '*') then 'All Traffic'
            when (r -> 'properties' ->> 'protocol' = 'icmp') then 'All ICMP'
            when sport is not null
            and dport is not null
            and sport = dport then concat(sport, '/', r -> 'properties' ->> 'protocol')
            else concat(
              sport,
              '-',
              dport,
              '/',
              r -> 'properties' ->> 'protocol'
            )
          end as port_proto,
          type,
          case
            when sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
                and (r -> 'properties' ->> 'protocol') <> 'icmp'
                and (
                  sport = '*'
                  or (sport:: integer = 0 and dport:: integer = 65535)
                ) then 'alert'
            else 'ok'
          end as category
        from
          azure_network_security_group,
          jsonb_array_elements(default_security_rules || security_rules) as r,
          jsonb_array_elements_text(r -> 'properties' -> 'sourceAddressPrefixes' || (r -> 'properties' -> 'sourceAddressPrefix') :: jsonb) as sip,
          jsonb_array_elements_text(r -> 'properties' -> 'destinationPortRanges' || (r -> 'properties' -> 'destinationPortRange') :: jsonb) dport,
          jsonb_array_elements_text(r -> 'properties' -> 'sourcePortRanges' || (r -> 'properties' -> 'sourcePortRange') :: jsonb) sport
        where
          r -> 'properties' ->> 'direction' = 'Inbound'
          and id = $1
          )

      -- Nodes  ---------

      select
        distinct concat('src_',cidr_block) as id,
        cidr_block as title,
        0 as depth,
        'source' as category,
        null as from_id,
        null as to_id
      from
        rules

      union
      select
        distinct port_proto as id,
        port_proto as title,
        1 as depth,
        'port_proto' as category,
        null as from_id,
        null as to_id
      from
        rules

      union
      select
        distinct id as id,
        category || '/' || title as title,
        3 as depth,
        category,
        trim((split_part(nsg_id, '/', 9)), '""') as from_id,
        null as to_id
      from
        associations

      -- Edges  ---------
      union select
        null as id,
        null as title,
        null as depth,
        category,
        concat('src_', cidr_block) as from_id,
        port_proto as to_id
      from
        rules

      union select
        null as id,
        null as title,
        null as depth,
        category,
        port_proto as from_id,
        trim((split_part(id, '/', 9)), '""') as to_id
      from
        rules
  EOQ

  param "id" {}
}

query "network_security_group_egress_rule_sankey" {
  sql = <<-EOQ

    with associations as (

      -- NICs
      select
        ni.title as title,
        'nsg' as category,
        ni.id as id,
        nsg.id as nsg_id
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(nsg.network_interfaces) as nic
        left join azure_network_interface as ni on lower(ni.id) = lower(nic ->> 'id')
      where
        nsg.id = $1

      -- Subnets
      union select
        s.title as title,
        'subnet' as category,
        s.id as id,
        nsg.id as nsg_id
      from
        azure_network_security_group as nsg,
        jsonb_array_elements(nsg.subnets) as subnets
        left join azure_subnet as s on lower(s.id) = lower(subnets ->> 'id')
      where
        nsg.id = $1
      ),
      rules as (
        select
          sip as cidr_block,
          id,
          case
            when (r -> 'properties' ->> 'protocol' = '*') then 'All Traffic'
            when (r -> 'properties' ->> 'protocol' = 'icmp') then 'All ICMP'
            when sport is not null
            and dport is not null
            and sport = dport then concat(sport, '/', r -> 'properties' ->> 'protocol')
            else concat(
              sport,
              '-',
              dport,
              '/',
              r -> 'properties' ->> 'protocol'
            )
          end as port_proto,
          type,
          case
            when sip in ('*', '0.0.0.0', '0.0.0.0/0', 'Internet', 'any', '<nw>/0', '/0')
                and (r -> 'properties' ->> 'protocol') <> 'icmp'
                and (
                  sport = '*'
                  or  (sport:: integer = 0 and dport:: integer = 65535)
                ) then 'alert'
            else 'ok'
          end as category
        from
          azure_network_security_group,
          jsonb_array_elements(default_security_rules || security_rules) as r,
          jsonb_array_elements_text(r -> 'properties' -> 'sourceAddressPrefixes' || (r -> 'properties' -> 'sourceAddressPrefix') :: jsonb) as sip,
          jsonb_array_elements_text(r -> 'properties' -> 'destinationPortRanges' || (r -> 'properties' -> 'destinationPortRange') :: jsonb) dport,
          jsonb_array_elements_text(r -> 'properties' -> 'sourcePortRanges' || (r -> 'properties' -> 'sourcePortRange') :: jsonb) sport
        where
          r -> 'properties' ->> 'direction' = 'Outbound'
          and id = $1
          )

        -- Nodes  ---------

      select
        distinct concat('src_',cidr_block) as id,
        cidr_block as title,
        3 as depth,
        'source' as category,
        null as from_id,
        null as to_id
      from
        rules

      union
      select
        distinct port_proto as id,
        port_proto as title,
        2 as depth,
        'port_proto' as category,
        null as from_id,
        null as to_id
      from
        rules

      union
      select
        distinct trim((split_part(nsg.id, '/', 9)), '""')  as id,
        trim((split_part(nsg.id, '/', 9)), '""') as title,
        1 as depth,
        'network_security_group' as category,
        null as from_id,
        null as to_id
      from
        azure_network_security_group as nsg
        inner join rules as r on lower(nsg.id) = lower(r.id)

      union
      select
          distinct id as id,
          category || '/' || title as title,
          0 as depth,
          category,
          trim((split_part(nsg_id, '/', 9)), '""') as from_id,
          null as to_id
        from
          associations

      -- Edges  ---------
      union select
        null as id,
        null as title,
        null as depth,
        category,
        concat('src_',cidr_block) as from_id,
        port_proto as to_id
      from
        rules

      union select
        null as id,
        null as title,
        null as depth,
        category,
        port_proto as from_id,
        trim((split_part(id, '/', 9)), '""') as to_id
      from
        rules
  EOQ

  param "id" {}
}
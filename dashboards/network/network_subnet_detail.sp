dashboard "network_subnet_detail" {

  title         = "Azure Network Subnet Detail"
  documentation = file("./dashboards/network/docs/network_subnet_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "subnet_id" {
    title = "Select a subnet:"
    query = query.network_subnet_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.network_subnet_num_ips
      args = {
        id = self.input.subnet_id.value
      }
    }

    card {
      width = 2
      query = query.network_subnet_address_prefix
      args = {
        id = self.input.subnet_id.value
      }
    }

  }

    with "app_service_web_apps" {
        sql = <<-EOQ
          select
            lower(id) as web_app_id
          from
            azure_app_service_web_app
          where
            lower(vnet_connection -> 'properties' ->> 'vnetResourceId') = $1
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "documentdb_cosmosdb_account_ids" {
        sql = <<-EOQ
          select
            lower(id) as cosmosdb_account_id
          from
            azure_cosmosdb_account,
            jsonb_array_elements(virtual_network_rules) as r
          where
            lower(r ->> 'id') = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "network_application_gateways" {
        sql = <<-EOQ
          select
            lower(id) as application_gateway_id
          from
            azure_application_gateway,
            jsonb_array_elements(gateway_ip_configurations) as c
          where
            lower(c -> 'properties' -> 'subnet' ->> 'id') = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "network_nat_gateways" {
        sql = <<-EOQ
          select
            lower(id) as nat_gateway_id
          from
            azure_nat_gateway,
            jsonb_array_elements(subnets) as s
          where
            lower(s ->> 'id') = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "network_route_tables" {
        sql = <<-EOQ
          select
            lower(r.id) as route_table_id
          from
            azure_route_table as r,
            jsonb_array_elements(r.subnets) as sub
          where
            lower(sub ->> 'id') = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "network_security_groups" {
        sql = <<-EOQ
          select
            lower(nsg.id) as nsg_id
          from
            azure_network_security_group as nsg,
            jsonb_array_elements(nsg.subnets) as sub
          where
            lower(sub ->> 'id') = $1
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "network_virtual_networks" {
        sql = <<-EOQ
          select
            lower(vn.id) as virtual_network_id
          from
            azure_subnet as s
            left join azure_virtual_network as vn on vn.name = s.virtual_network_name
          where
            lower(s.subscription_id) = lower(vn.subscription_id)
            and lower(s.resource_group) = lower(vn.resource_group)
            and lower(s.id) = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "sql_servers" {
        sql = <<-EOQ
          select
            lower(id) as sql_server_id
          from
            azure_sql_server,
            jsonb_array_elements(virtual_network_rules) as r
          where
            lower(r -> 'properties' ->> 'virtualNetworkSubnetId') = $1
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "storage_storage_accounts" {
        sql = <<-EOQ
          select
            lower(id) as storage_account_id
          from
            azure_storage_account,
            jsonb_array_elements(virtual_network_rules) as r
          where
            lower(r ->> 'id') = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"
      
  node {
    base = node.app_service_web_app
    args = {
      app_service_web_app_ids = with.app_service_web_apps.rows[*].web_app_id
    }
  }

  node {
    base = node.documentdb_cosmosdb_account
    args = {
      documentdb_cosmosdb_account_ids = with.documentdb_cosmosdb_account_ids.rows[*].cosmosdb_account_id
    }
  }

  node {
    base = node.network_application_gateway
    args = {
      network_application_gateway_ids = with.network_application_gateways.rows[*].application_gateway_id
    }
  }

  node {
    base = node.network_nat_gateway
    args = {
      network_nat_gateway_ids = with.network_nat_gateways.rows[*].nat_gateway_id
    }
  }

  node {
    base = node.network_network_security_group
    args = {
      network_security_group_ids = with.network_security_groups.rows[*].nsg_id
    }
  }

  node {
    base = node.network_route_table
    args = {
      network_route_table_ids = with.network_route_tables.rows[*].route_table_id
    }
  }

  node {
    base = node.network_subnet
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  node {
    base = node.network_subnet_api_management
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  node {
    base = node.network_virtual_network
    args = {
      network_virtual_network_ids = with.network_virtual_networks.rows[*].virtual_network_id
    }
  }

  node {
    base = node.sql_server
    args = {
      sql_server_ids = with.sql_servers.rows[*].sql_server_id
    }
  }

  node {
    base = node.storage_storage_account
    args = {
      storage_account_ids = with.storage_storage_accounts.rows[*].storage_account_id
    }
  }

  edge {
    base = edge.network_subnet_to_api_management
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_subnet_to_app_service_web_app
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_subnet_to_documentdb_cosmosdb_account
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_subnet_to_network_application_gateway
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_subnet_to_network_nat_gateway
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_subnet_to_network_route_table
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_subnet_to_network_security_group
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_subnet_to_sql_server
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_subnet_to_storage_storage_account
    args = {
      network_subnet_ids = [self.input.subnet_id.value]
    }
  }

  edge {
    base = edge.network_virtual_network_to_network_subnet
    args = {
      network_virtual_network_ids = with.network_virtual_networks.rows[*].virtual_network_id
    }
  }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 12
        query = query.network_subnet_overview
        args = {
          id = self.input.subnet_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Launched Resources"
        query = query.network_subnet_association
        args = {
          id = self.input.subnet_id.value
        }

        column "link" {
          display = "none"
        }

        column "Title" {
          href = "{{ .link }}"
        }

      }

    }

  }

}

query "network_subnet_input" {
  sql = <<-EOQ
    select
      g.title as label,
      lower(g.id) as value,
      json_build_object(
        'subscription', s.display_name,
        'virtual_network_name', g.virtual_network_name,
        'resource_group', g.resource_group
      ) as tags
    from
      azure_subnet as g,
      azure_subscription as s
    where
      lower(g.subscription_id) = lower(s.subscription_id)
    order by
      g.title;
  EOQ
}

query "network_subnet_num_ips" {
  sql = <<-EOQ
    select
      power(2, 32 - masklen(address_prefix:: cidr)) as "IP Addresses"
    from
      azure_subnet
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_subnet_address_prefix" {
  sql = <<-EOQ
    select
      address_prefix as "Address Prefix"
    from
      azure_subnet
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_subnet_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      type as "Type",
      etag as "ETag",
      virtual_network_name as "Virtual Network Name",
      provisioning_state  as "Provisioning State",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_subnet
    where
      lower(id) = $1;
  EOQ

  param "id" {}
}

query "network_subnet_association" {
  sql = <<-EOQ

    -- API Management
    select
      title as "Title",
      type as "Type",
      id as "ID",
      null as link
    from
      azure_api_management
    where
      lower(virtual_network_configuration_subnet_resource_id) = $1

    -- CosmosDB Account
    union all
    select
      title as "Title",
      type as "Type",
      id as "ID",
      null as link
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
     lower(r ->> 'id') = $1

    -- Storage Account
    union all
    select
      title as "Title",
      type as "Type",
      id as "ID",
      '${dashboard.storage_account_detail.url_path}?input.storage_account_id=' || id as link
    from
      azure_storage_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r ->> 'id') = $1

    -- SQL Server
    union all
    select
      title as "Title",
      type as "Type",
      id as "ID",
      '${dashboard.sql_server_detail.url_path}?input.server_id=' || id as link
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r -> 'properties' ->> 'virtualNetworkSubnetId') = $1

    -- AppServcie Web App
    union all
    select
      title as "Title",
      type as "Type",
      id as "ID",
      null as link
    from
      azure_app_service_web_app
    where
      lower(vnet_connection -> 'properties' ->> 'vnetResourceId') = $1

    -- Application Gateway
    union all
    select
      title as "Title",
      type as "Type",
      id as "ID",
      null as link
    from
      azure_application_gateway,
      jsonb_array_elements(gateway_ip_configurations) as c
    where
      lower(c -> 'properties' -> 'subnet' ->> 'id') = $1

    -- Network Security Groups
    union all
    select
      title as "Title",
      type as "Type",
      id as "ID",
      null as link
    from
      azure_network_security_group as nsg,
      jsonb_array_elements(nsg.subnets) as sub
    where
      lower(sub ->> 'id') = $1

    -- Route Tables
    union all
    select
      title as "Title",
      type as "Type",
      id as "ID",
      null as link
    from
      azure_route_table as r,
      jsonb_array_elements(r.subnets) as sub
    where
      lower(sub ->> 'id') = $1;
  EOQ

  param "id" {}
}

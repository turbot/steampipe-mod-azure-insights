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

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "virtual_networks" {
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

      with "web_apps" {
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

      with "storage_accounts" {
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

      nodes = [
        node.network_subnet,
        node.network_virtual_network,
        node.network_subnet_route_table,
        node.network_subnet_nat_gateway,
        node.network_network_security_group,
        node.app_service_web_app,
        node.sql_server,
        node.storage_storage_account,
        node.network_subnet_cosmosdb_account,
        node.network_subnet_api_management,
        node.network_subnet_application_gateway
      ]

      edges = [
        edge.network_virtual_network_to_network_subnet,
        edge.network_subnet_to_network_route_table,
        edge.network_subnet_to_network_nat_gateway,
        edge.network_subnet_to_network_security_group,
        edge.network_subnet_to_app_service_web_app,
        edge.network_subnet_to_sql_server,
        edge.network_subnet_to_storage_storage_account,
        edge.network_subnet_to_cosmosdb_account,
        edge.network_subnet_to_api_management,
        edge.network_subnet_to_network_application_gateway
      ]

      args = {
        network_subnet_ids         = [self.input.subnet_id.value]
        virtual_network_ids        = with.virtual_networks.rows[*].virtual_network_id
        network_security_group_ids = with.network_security_groups.rows[*].nsg_id
        web_app_ids                = with.web_apps.rows[*].web_app_id
        id                         = self.input.subnet_id.value
        sql_server_ids             = with.sql_servers.rows[*].sql_server_id
        storage_account_ids        = with.storage_accounts.rows[*].storage_account_id
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
      '${dashboard.azure_storage_account_detail.url_path}?input.storage_account_id=' || id as link
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
      '${dashboard.azure_sql_server_detail.url_path}?input.server_id=' || id as link
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

node "network_subnet" {
  category = category.azure_subnet

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'Etag', etag,
        'Type', type,
        'Virtual Network Name', virtual_network_name,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_subnet
    where
      lower(id) = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "azure_network_subnet_from_virtual_network_node" {
  category = category.azure_virtual_network

  sql = <<-EOQ
    select
      vn.id as id,
      vn.title as title,
      jsonb_build_object(
        'Name', vn.name,
        'ID', vn.id,
        'Etag', vn.etag,
        'Type', vn.type,
        'Region', vn.region,
        'Resource Group', vn.resource_group,
        'Subscription ID', vn.subscription_id
      ) as properties
    from
      azure_subnet as s
      left join azure_virtual_network as vn on vn.name = s.virtual_network_name
    where
      lower(s.subscription_id) = lower(vn.subscription_id)
      and lower(s.resource_group) = lower(vn.resource_group)
      and lower(s.id) = $1;
  EOQ

  param "id" {}
}

edge "azure_network_subnet_from_virtual_network_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      vn.id as from_id,
      s.id as to_id
    from
      azure_subnet as s
      left join azure_virtual_network as vn on vn.name = s.virtual_network_name
    where
      lower(s.subscription_id) = lower(vn.subscription_id)
      and lower(s.resource_group) = lower(vn.resource_group)
      and lower(s.id) = $1;
  EOQ

  param "id" {}
}

node "network_subnet_route_table" {
  category = category.azure_route_table

  sql = <<-EOQ
    select
      lower(r.id) as id,
      r.title as title,
      jsonb_build_object(
        'Name', r.name,
        'ID', r.id,
        'Type', r.type,
        'Resource Group', r.resource_group,
        'Subscription ID', r.subscription_id
      ) as properties
    from
      azure_route_table as r,
      jsonb_array_elements(r.subnets) as sub
    where
      lower(sub ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_network_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      lower(sub ->> 'id') as from_id,
      lower(r.id) as to_id
    from
      azure_route_table as r,
      jsonb_array_elements(r.subnets) as sub
    where
      lower(sub ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "azure_network_subnet_to_network_security_group_node" {
  category = category.azure_network_security_group

  sql = <<-EOQ
    select
      nsg.id as id,
      nsg.title as title,
      jsonb_build_object(
        'ID', nsg.id,
        'Name', nsg.name,
        'Type', nsg.type,
        'Resource Group', nsg.resource_group,
        'Subscription ID', nsg.subscription_id
      ) as properties
    from
      azure_network_security_group as nsg,
      jsonb_array_elements(nsg.subnets) as sub
    where
      sub ->> 'id' = $1
  EOQ

  param "id" {}

}

edge "network_subnet_to_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      nsg_id as to_id
    from
      unnest($1::text[]) as subnet_id,
      unnest($2::text[]) as nsg_id
  EOQ

  param "network_subnet_ids" {}
  param "network_security_group_ids" {}
}

node "network_subnet_application_gateway" {
  category = category.azure_application_gateway

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_application_gateway,
      jsonb_array_elements(gateway_ip_configurations) as c
    where
      lower(c -> 'properties' -> 'subnet' ->> 'id') = any($1)
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_network_application_gateway" {
  title = "application gateway"

  sql = <<-EOQ
    select
      lower(c -> 'properties' -> 'subnet' ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_application_gateway,
      jsonb_array_elements(gateway_ip_configurations) as c
    where
      lower(c -> 'properties' -> 'subnet' ->> 'id') = any($1)
  EOQ

  param "network_subnet_ids" {}
}

node "network_subnet_nat_gateway" {
  category = category.azure_nat_gateway

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_nat_gateway,
      jsonb_array_elements(subnets) as s
    where
      lower(s ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_network_nat_gateway" {
  title = "nat gateway"

  sql = <<-EOQ
    select
      lower(s ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_nat_gateway,
      jsonb_array_elements(subnets) as s
    where
      lower(s ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "azure_network_subnet_to_app_service_web_app_node" {
  category = category.azure_app_service_web_app

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Name', name,
        'Type', type,
        'Kind', kind,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_app_service_web_app
    where
      vnet_connection -> 'properties' ->> 'vnetResourceId' = $1
  EOQ

  param "id" {}
}

edge "network_subnet_to_app_service_web_app" {
  title = "web app"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      web_app_id as to_id
    from
     unnest($1::text[]) as web_app_id,
     unnest($2::text[]) as subnet_id
  EOQ

  param "web_app_ids" {}
  param "network_subnet_ids" {}
}

node "azure_network_subnet_to_sql_server_node" {
  category = category.sql_server

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Kind', kind,
        'Version', version,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as r
    where
      r -> 'properties' ->> 'virtualNetworkSubnetId' = $1
  EOQ

  param "id" {}
}

edge "network_subnet_to_sql_server" {
  title = "sql server"

  sql = <<-EOQ
    select
      lower(r -> 'properties' ->> 'virtualNetworkSubnetId') as from_id,
      lower(id) as to_id
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r -> 'properties' ->> 'virtualNetworkSubnetId') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "azure_network_subnet_to_storage_account_node" {
  category = category.azure_storage_account

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'SKU Name', sku_name,
        'Access Tier', access_tier,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_storage_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      r ->> 'id' = $1;
  EOQ

  param "id" {}
}

edge "network_subnet_to_storage_storage_account" {
  title = "storage account"

  sql = <<-EOQ
    select
      lower(r ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_storage_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "network_subnet_cosmosdb_account" {
  category = category.azure_cosmosdb_account

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_cosmosdb_account" {
  title = "cosmosdb"

  sql = <<-EOQ
    select
      lower(r ->> 'id') as from_id,
      lower(id) as to_id
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      lower(r ->> 'id') = any($1);
  EOQ

  param "network_subnet_ids" {}
}

node "network_subnet_api_management" {
  category = category.azure_api_management

  sql = <<-EOQ
    select
      lower(id) as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ID', id,
        'ETag', etag,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id
      ) as properties
    from
      azure_api_management
    where
      lower(virtual_network_configuration_subnet_resource_id) = any($1);
  EOQ

  param "network_subnet_ids" {}
}

edge "network_subnet_to_api_management" {
  title = "api management"

  sql = <<-EOQ
    select
      lower(virtual_network_configuration_subnet_resource_id) as from_id,
      lower(id) as to_id
    from
      azure_api_management
    where
      lower(virtual_network_configuration_subnet_resource_id) = any($1);
  EOQ

  param "network_subnet_ids" {}
}

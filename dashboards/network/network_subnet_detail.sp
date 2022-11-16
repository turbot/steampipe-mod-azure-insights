dashboard "azure_network_subnet_detail" {

  title         = "Azure Network Subnet Detail"
  documentation = file("./dashboards/network/docs/network_subnet_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "subnet_id" {
    title = "Select a subnet:"
    query = query.azure_network_subnet_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_network_subnet_num_ips
      args  = {
        id = self.input.subnet_id.value
      }
    }

    card {
      width = 2
      query = query.azure_network_subnet_address_prefix
      args  = {
        id = self.input.subnet_id.value
      }
    }

  }

   container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.azure_network_subnet_node,
        node.azure_network_subnet_from_virtual_network_node,
        node.azure_network_subnet_to_route_table_node,
        node.azure_network_subnet_to_nat_gateway_node,
        node.azure_network_subnet_to_network_security_group_node,
        node.azure_network_subnet_to_app_service_web_app_node,
        node.azure_network_subnet_to_sql_server_node,
        node.azure_network_subnet_to_storage_account_node,
        node.azure_network_subnet_to_cosmosdb_account_node,
        node.azure_network_subnet_to_api_management_node,
        node.azure_network_subnet_to_application_gateway_node
      ]

      edges = [
        edge.azure_network_subnet_from_virtual_network_edge,
        edge.azure_network_subnet_to_route_table_edge,
        edge.azure_network_subnet_to_nat_gateway_edge,
        edge.azure_network_subnet_to_network_security_group_edge,
        edge.azure_network_subnet_to_app_service_web_app_edge,
        edge.azure_network_subnet_to_sql_server_edge,
        edge.azure_network_subnet_to_storage_account_edge,
        edge.azure_network_subnet_to_cosmosdb_account_edge,
        edge.azure_network_subnet_to_api_management_edge,
        edge.azure_network_subnet_to_application_gateway_edge
      ]

      args = {
        id = self.input.subnet_id.value
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
        query = query.azure_network_subnet_overview
        args = {
          id = self.input.subnet_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Launched Resources"
        query = query.azure_network_subnet_association
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

query "azure_network_subnet_input" {
  sql = <<-EOQ
    select
      g.title as label,
      g.id as value,
      json_build_object(
        'subscription', s.display_name,
        'virtual_network_name', g.virtual_network_name,
        'resource_group', g.resource_group
      ) as tags
    from
      azure_subnet as g,
      azure_subscription as s
    where
      g.subscription_id = s.subscription_id
    order by
      g.title;
  EOQ
}

query "azure_network_subnet_num_ips" {
  sql = <<-EOQ
    select
      power(2, 32 - masklen(address_prefix:: cidr)) as "IP Addresses"
    from
      azure_subnet
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_subnet_address_prefix" {
  sql = <<-EOQ
    select
      address_prefix as "Address Prefix"
    from
      azure_subnet
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_subnet_overview" {
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
      id = $1;
  EOQ

  param "id" {}
}

query "azure_network_subnet_association" {
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
      virtual_network_configuration_subnet_resource_id = $1

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
      r ->> 'id' = $1

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
      r ->> 'id' = $1

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
      r -> 'properties' ->> 'virtualNetworkSubnetId' = $1

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
      vnet_connection -> 'properties' ->> 'vnetResourceId' = $1

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
      c -> 'properties' -> 'subnet' ->> 'id' = $1

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
      sub ->> 'id' = $1

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
      sub ->> 'id' = $1;
  EOQ

  param "id" {}
}

category "azure_network_subnet_no_link" {
  icon  = "share"
  color = "purple"
}

node "azure_network_subnet_node" {
  category = category.azure_network_subnet_no_link

  sql = <<-EOQ
    select
      id as id,
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
      id = $1;
  EOQ

  param "id" {}
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
      s.subscription_id = vn.subscription_id
      and s.resource_group = vn.resource_group
      and s.id = $1;
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
      s.subscription_id = vn.subscription_id
      and s.resource_group = vn.resource_group
      and s.id = $1;
  EOQ

  param "id" {}
}

node "azure_network_subnet_to_route_table_node" {
  category = category.azure_route_table

  sql = <<-EOQ
    select
      r.id as id,
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
      sub ->> 'id' = $1;
  EOQ

  param "id" {}
}

edge "azure_network_subnet_to_route_table_edge" {
  title = "route table"

  sql = <<-EOQ
    select
      sub ->> 'id' as from_id,
      r.id as to_id
    from
      azure_route_table as r,
      jsonb_array_elements(r.subnets) as sub
    where
      sub ->> 'id' = $1
  EOQ

  param "id" {}
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

edge "azure_network_subnet_to_network_security_group_edge" {
  title = "nsg"

  sql = <<-EOQ
    select
      sub ->> 'id' as from_id,
      nsg.id as to_id
    from
      azure_network_security_group as nsg,
      jsonb_array_elements(nsg.subnets) as sub
    where
      sub ->> 'id' = $1
  EOQ

  param "id" {}
}

node "azure_network_subnet_to_application_gateway_node" {
  category = category.azure_application_gateway

  sql = <<-EOQ
    select
      id as id,
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
      c -> 'properties' -> 'subnet' ->> 'id' = $1
  EOQ

  param "id" {}
}

edge "azure_network_subnet_to_application_gateway_edge" {
  title = "application gateway"

  sql = <<-EOQ
    select
      $1 as from_id,
      id as to_id
    from
      azure_application_gateway,
      jsonb_array_elements(gateway_ip_configurations) as c
    where
      c -> 'properties' -> 'subnet' ->> 'id' = $1
  EOQ

  param "id" {}
}

node "azure_network_subnet_to_nat_gateway_node" {
  category = category.azure_nat_gateway

  sql = <<-EOQ
    select
      id as id,
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
      s ->> 'id' = $1;
  EOQ

  param "id" {}
}

edge "azure_network_subnet_to_nat_gateway_edge" {
  title = "nat gateway"

  sql = <<-EOQ
    select
      $1 as from_id,
      id as to_id
    from
      azure_nat_gateway,
      jsonb_array_elements(subnets) as s
    where
      s ->> 'id' = $1;
  EOQ

  param "id" {}
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

edge "azure_network_subnet_to_app_service_web_app_edge" {
  title = "web app"

  sql = <<-EOQ
    select
      $1 as from_id,
      id as to_id
    from
      azure_app_service_web_app
    where
      vnet_connection -> 'properties' ->> 'vnetResourceId' = $1
  EOQ

  param "id" {}
}

node "azure_network_subnet_to_sql_server_node" {
  category = category.azure_sql_server

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

edge "azure_network_subnet_to_sql_server_edge" {
  title = "sql server"

  sql = <<-EOQ
    select
      $1 as from_id,
      id as to_id
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as r
    where
      r -> 'properties' ->> 'virtualNetworkSubnetId' = $1
  EOQ

  param "id" {}
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

edge "azure_network_subnet_to_storage_account_edge" {
  title = "storage account"

  sql = <<-EOQ
    select
      $1 as from_id,
      id as to_id
    from
      azure_storage_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      r ->> 'id' = $1;
  EOQ

  param "id" {}
}

node "azure_network_subnet_to_cosmosdb_account_node" {
  category = category.azure_cosmosdb_account

  sql = <<-EOQ
    select
      id as id,
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
      r ->> 'id' = $1;
  EOQ

  param "id" {}
}

edge "azure_network_subnet_to_cosmosdb_account_edge" {
  title = "cosmosdb account"

  sql = <<-EOQ
    select
      $1 as from_id,
      id as to_id
    from
      azure_cosmosdb_account,
      jsonb_array_elements(virtual_network_rules) as r
    where
      r ->> 'id' = $1;
  EOQ

  param "id" {}
}

node "azure_network_subnet_to_api_management_node" {
  category = category.azure_api_management

  sql = <<-EOQ
    select
      id as id,
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
      virtual_network_configuration_subnet_resource_id = $1;
  EOQ

  param "id" {}
}

edge "azure_network_subnet_to_api_management_edge" {
  title = "api management"

  sql = <<-EOQ
    select
      $1 as from_id,
      id as to_id
    from
      azure_api_management
    where
      virtual_network_configuration_subnet_resource_id = $1;
  EOQ

  param "id" {}
}
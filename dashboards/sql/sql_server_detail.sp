dashboard "azure_sql_server_detail" {

  title         = "Azure SQL Server Detail"
  documentation = file("./dashboards/sql/docs/sql_server_detail.md")

  tags = merge(local.sql_common_tags, {
    type = "Detail"
  })

  input "server_id" {
    title = "Select a server:"
    query = query.azure_sql_server_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.azure_sql_server_state
      args = {
        id = self.input.server_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_server_version
      args = {
        id = self.input.server_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_server_auditing_enabled
      args = {
        id = self.input.server_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_server_public_network_access
      args = {
        id = self.input.server_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_server_ad_authentication_enabled
      args = {
        id = self.input.server_id.value
      }
    }

    card {
      width = 2
      query = query.azure_sql_server_vulnerability_assessment_enabled
      args = {
        id = self.input.server_id.value
      }
    }


  }

  container {
    graph {
      title = "Relationships"
      type  = "graph"
      direction = "TD"

      nodes = [
        node.azure_sql_server_node,
        node.azure_sql_server_to_firewall_rule_node,
        node.azure_sql_server_to_audit_policy_node,
        node.azure_sql_server_from_subnet_node,
        node.azure_sql_server_subnet_from_virtual_network_node,
        node.azure_sql_server_to_key_vault_node,
        node.azure_sql_server_keyvault_to_key_vault_key_node,
        node.azure_sql_server_to_sql_database_node,
        node.azure_sql_server_to_private_endpoint_node
      ]

      edges = [
        edge.azure_sql_server_to_firewall_rule_edge,
        edge.azure_sql_server_to_audit_policy_edge,
        edge.azure_sql_server_from_subnet_edge,
        edge.azure_sql_server_subnet_from_virtual_network_edge,
        edge.azure_sql_server_to_key_vault_edge,
        edge.azure_sql_server_keyvault_to_key_vault_key_edge,
        edge.azure_sql_server_to_sql_database_edge,
        edge.azure_sql_server_to_private_endpoint_edge
      ]

      args = {
        id = self.input.server_id.value
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
        query = query.azure_sql_server_overview
        args = {
          id = self.input.server_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.azure_sql_server_tags
        args = {
          id = self.input.server_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Encryption"
        query = query.azure_sql_server_encryption
        args = {
          id = self.input.server_id.value
        }
      }

      table {
        title = "Virtual Network Rules"
        query = query.azure_sql_server_virtual_network_rules
        args = {
          id = self.input.server_id.value
        }
      }

    }

  }

  container {
    width = 12

    table {
      title = "Audit Policy"
      query = query.azure_sql_server_audit_policy
      args = {
        id = self.input.server_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Vulnerability Assessment"
      query = query.azure_sql_server_vulnerability_assessment
      args = {
        id = self.input.server_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Private Endpoint Details"
      query = query.azure_sql_server_private_endpoint_connection
      args = {
        id = self.input.server_id.value
      }
    }

  }

}

query "azure_sql_server_input" {
  sql = <<-EOQ
    select
      s.title as label,
      s.id as value,
      json_build_object(
        'subscription', sub.display_name,
        'resource_group', s.resource_group,
        'region', s.region
      ) as tags
    from
      azure_sql_server as s,
      azure_subscription as sub
    where
      s.subscription_id = s.subscription_id
    order by
      s.title;
  EOQ
}

query "azure_sql_server_state" {
  sql = <<-EOQ
    select
      'State' as label,
      state as value
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}

}

query "azure_sql_server_version" {
  sql = <<-EOQ
    select
      'Version' as label,
      version as value
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_auditing_enabled" {
  sql = <<-EOQ
    with sql_server_audit_enabled as (
      select
        distinct id
      from
        azure_sql_server as s,
        jsonb_array_elements(server_audit_policy) as audit
      where
        audit -> 'properties' ->> 'state' = 'Enabled'
    )
    select
      'Auditing' as label,
      case when a.id is not null then 'Enabled' else 'Disabled' end as value,
      case when a.id is not null then 'ok' else 'alert' end as type
    from
      azure_sql_server as s left join sql_server_audit_enabled as a on s.id = a.id;
  EOQ
}

query "azure_sql_server_public_network_access" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when public_network_access = 'Enabled' then 'Enabled' else 'Disabled' end as value,
      case when public_network_access = 'Enabled' then 'alert' else 'ok' end as type
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_ad_authentication_enabled" {
  sql = <<-EOQ
    select
      'Azure AD Authentication' as label,
      case when server_azure_ad_administrator is not null then 'Enabled' else 'Disabled' end as value,
      case when server_azure_ad_administrator is not null then 'ok' else 'alert' end as type
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_vulnerability_assessment_enabled" {
  sql = <<-EOQ
    with sql_server_va as (
      select
        distinct id
      from
        azure_sql_server as s,
        jsonb_array_elements(server_vulnerability_assessment) as va
      where
        va -> 'properties' -> 'recurringScans' ->> 'isEnabled' = 'true'
    )
    select
      'Vulnerability Assessment' as label,
      case when v.id is not null then 'Enabled' else 'Disabled' end as value,
      case when v.id is not null then 'ok' else 'alert' end as type
    from
      azure_sql_server as s left join sql_server_va as v on s.id = v.id
      where s.id = $1;
  EOQ

  param "id" {}
}

node "azure_sql_server_node" {
  category = category.azure_sql_server

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Region', region,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id,
        'Fully Qualified Domain Name', fully_qualified_domain_name,
        'Type', type
      ) as properties
    from
      azure_sql_server
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_sql_server_to_firewall_rule_node"{
  category = category.azure_sql_server_firewall

  sql = <<-EOQ
    select
      rule -> 'id' as id,
      rule -> 'name' as title,
      json_build_object(
        'Name', rule -> 'name',
        'Start IP Address', rule -> 'properties' -> 'startIpAddress',
        'End IP Address', rule -> 'properties' -> 'endIpAddress',
        'Type', rule -> 'type'
      ) as properties
    from
      azure_sql_server,
      jsonb_array_elements(firewall_rules) as rule
    where
      id = $1;
  EOQ

  param "id" {}
}

edge "azure_sql_server_to_firewall_rule_edge" {
  title = "firewall rule"

  sql = <<-EOQ
    select
      id as from_id,
      rule -> 'id' as to_id
    from
      azure_sql_server,
      jsonb_array_elements(firewall_rules) as rule
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_sql_server_to_audit_policy_node" {
  category = category.azure_sql_server_audit_policy

  sql = <<-EOQ
    select
      sap -> 'id' as id,
      sap -> 'name' as title,
      json_build_object(
        'Name', sap -> 'name',
        'Retention Days', sap -> 'properties' -> 'retentionDays',
        'State', sap -> 'properties' -> 'state',
        'Azure Monitor Target Enabled', sap -> 'properties' -> 'isAzureMonitorTargetEnabled',
        'Storage Secondary Key In Use', sap -> 'properties' -> 'isStorageSecondaryKeyInUse',
        'Type', sap -> 'type'
      ) as properties
    from
      azure_sql_server,
      jsonb_array_elements(server_audit_policy) as sap
    where
      id = $1;
  EOQ

  param "id" {}
}

edge "azure_sql_server_to_audit_policy_edge"  {
  title = "audit policy"

  sql = <<-EOQ
    select
      id as from_id,
      sap -> 'id' as to_id
    from
      azure_sql_server,
      jsonb_array_elements(server_audit_policy) as sap
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_sql_server_from_subnet_node" {
  category = category.azure_subnet

  sql = <<-EOQ
    select
      id as id,
      title as title,
      json_build_object(
        'Name', name,
        'Type', type,
        'Address_prefix', address_prefix,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id,
        'ID', id
      ) as properties
    from
      azure_subnet
    where
      id in (
        select
          vnr -> 'properties' ->> 'virtualNetworkSubnetId'
        from
          azure_sql_server,
          jsonb_array_elements(virtual_network_rules) as vnr
        where
          id = $1
      );
  EOQ

  param "id" {}
}

edge "azure_sql_server_from_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      vnr -> 'properties' ->> 'virtualNetworkSubnetId' as from_id,
      id as to_id
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as vnr
    where
      id = $1;
  EOQ

  param "id" {}
}

node "azure_sql_server_subnet_from_virtual_network_node" {
  category = category.azure_virtual_network

  sql = <<-EOQ
    select
      id as id,
      title as title,
      json_build_object(
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id,
        'Address Prefixes', jsonb_array_elements_text(address_prefixes),
        'ID', id
      ) as properties
    from
      azure_virtual_network,
      jsonb_array_elements(subnets) as sub
    where
      sub ->> 'id' in (
        select
          vnr -> 'properties' ->> 'virtualNetworkSubnetId'
        from
          azure_sql_server,
          jsonb_array_elements(virtual_network_rules) as vnr
        where
          id = $1
      );
  EOQ

  param "id" {}
}

edge "azure_sql_server_subnet_from_virtual_network_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      id as from_id,
      sub ->> 'id' as to_id
    from
      azure_virtual_network,
      jsonb_array_elements(subnets) as sub
    where
      sub ->> 'id' in (
        select
          vnr -> 'properties' ->> 'virtualNetworkSubnetId'
        from
          azure_sql_server,
          jsonb_array_elements(virtual_network_rules) as vnr
        where
          id = $1
      );
  EOQ

  param "id" {}
}

node "azure_sql_server_to_key_vault_node" {
  category = category.azure_key_vault

  sql = <<-EOQ
    select
      id as id,
      name as title,
      json_build_object(
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id,
        'Soft Delete Enabled', soft_delete_enabled,
        'Soft Delete Retention Days', soft_delete_retention_in_days,
        'ID', id
      ) as properties
    from
      azure_key_vault
    where
      name in (
        select
          split_part(ep ->> 'serverKeyName','_',1) as key_vault_name
        from
          azure_sql_server,
          jsonb_array_elements(encryption_protector) as ep
        where
          id = $1 
          and ep ->> 'kind' = 'azurekeyvault'
      );
    
  EOQ
  param "id" {}
}

edge "azure_sql_server_to_key_vault_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    with key_vault as (
      select
        id as to_id,
        name as key_vault_name
      from
        azure_key_vault
      where
        name in (
          select
            split_part(ep ->> 'serverKeyName','_',1) as key_vault_name
          from
            azure_sql_server,
            jsonb_array_elements(encryption_protector) as ep
          where
            id = $1
            and ep ->> 'kind' = 'azurekeyvault'
        )
    )
    select
      id as from_id,
      kv.to_id as to_id
    from
      azure_sql_server,
      key_vault as kv
    where
      id = $1
  EOQ

  param "id" {}
}

node "azure_sql_server_keyvault_to_key_vault_key_node" {
  category = category.azure_key_vault_key

  sql = <<-EOQ
    with all_keys as (
      select
        name as key_vault_key_name,
        vault_name as key_vault_name,
        id,
        type,
        resource_group,
        subscription_id,
        curve_name,
        enabled,
        expires_at,
        key_type
      from 
        azure_key_vault_key
    ),
    attached_keys as (
      select
        split_part(ep ->> 'serverKeyName','_',1) as key_vault_name,
        split_part(ep ->> 'serverKeyName','_',2) as key_vault_key_name
      from
        azure_sql_server,
        jsonb_array_elements(encryption_protector) as ep
      where
        id = $1
        and ep ->> 'kind' = 'azurekeyvault'
    )
    select
      b.id as id,
      b.key_vault_key_name as title,
      json_build_object(
        'Name', b.key_vault_key_name,
        'Type', b.type,
        'Resource Group', b.resource_group,
        'Subscription ID', b.subscription_id,
        'Curve Name', b.curve_name,
        'Enabled', b.enabled,
        'Expires At', b.expires_at,
        'Key Type', b.key_type,
        'ID',b.id
      ) as properties
    from
      attached_keys as a
      left join all_keys as b on a.key_vault_key_name = b.key_vault_key_name;
  EOQ

  param "id" {}
}

edge "azure_sql_server_keyvault_to_key_vault_key_edge" {
  title = "contains"

  sql = <<-EOQ
    with all_keys as (
      select
        id,
        name as key_vault_key_name,
        vault_name as key_vault_name,
        concat('/subscriptions/',subscription_id,'/resourceGroups/',resource_group,'/providers/Microsoft.KeyVault/vaults/',vault_name) as key_vault_id
      from 
        azure_key_vault_key
    ),
    attached_keys as (
      select
        split_part(ep ->> 'serverKeyName','_',1) as key_vault_name,
        split_part(ep ->> 'serverKeyName','_',2) as key_vault_key_name
      from
        azure_sql_server,
        jsonb_array_elements(encryption_protector) as ep
      where
        id = $1
        and ep ->> 'kind' = 'azurekeyvault'
    )
    select
      b.id as to_id,
      b.key_vault_id as from_id
    from
      attached_keys as a
      left join all_keys as b on a.key_vault_key_name = b.key_vault_key_name;
  EOQ

  param "id" {}
}

node "azure_sql_server_to_sql_database_node" {
  category = category.azure_sql_database
  
  sql = <<-EOQ
    select
      id as id,
      name as title,
      json_build_object(
        'Name', name,
        'Type', type,
        'Resource Group', resource_group,
        'Subscription ID', subscription_id,
        'Zone Redundant', zone_redundant,
        'Status', status,
        'ID', id
      ) as properties
    from
      azure_sql_database
    where
      server_name = split_part($1, '/', 9);
  EOQ

  param "id" {}
}

edge "azure_sql_server_to_sql_database_edge" {
  title = "database"

  sql = <<-EOQ
    select
      $1 as from_id,
      id as to_id
    from
      azure_sql_database
    where
      server_name = split_part($1, '/', 9);
  EOQ

  param "id" {}
}

node "azure_sql_server_to_private_endpoint_node" {
  category = category.azure_sql_server_private_endpoint_connection

  sql = <<-EOQ
    select
      pec ->> 'PrivateEndpointConnectionId' as id,
      split_part(pec ->> 'PrivateEndpointId','/',9) as title,
      json_build_object(
        'Private Endpoint Connection Name', pec ->> 'PrivateEndpointConnectionName',
        'Type', pec ->> 'PrivateEndpointConnectionType',
        'Provisioning State', pec ->> 'ProvisioningState'
      ) as properties
    from
      azure_sql_server,
      jsonb_array_elements(private_endpoint_connections) as pec
    where
      id = $1;
  EOQ

  param "id" {}
}

edge "azure_sql_server_to_private_endpoint_edge" {
  title = "private endpoint"

  sql = <<-EOQ
    select
      pec ->> 'PrivateEndpointConnectionId' as to_id,
      id as from_id
    from
      azure_sql_server,
      jsonb_array_elements(private_endpoint_connections) as pec
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      fully_qualified_domain_name as "Fully Qualified Domain Name",
      minimal_tls_version as "Minimal TLS Version",
      region as "Region",
      resource_group as "Resource Group",
      subscription_id as "Subscription ID",
      id as "ID"
    from
      azure_sql_server
    where
      id = $1
  EOQ

  param "id" {}
}

query "azure_sql_server_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_sql_server,
      jsonb_each_text(tags) as tag
    where
      id = $1
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "azure_sql_server_encryption" {
  sql = <<-EOQ
    select
      ep ->> 'name' as "Name",
      ep ->> 'kind' as "Kind",
      ep ->> 'serverKeyName' as "Server Key Name",
      ep ->> 'serverKeyType' as "Server Key Type",
      ep ->> 'type' as "Type",
      ep ->> 'id' as "ID"
    from
      azure_sql_server,
      jsonb_array_elements(encryption_protector) as ep
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_virtual_network_rules" {
  sql = <<-EOQ
    select
      r ->> 'name' as "Name",
      r -> 'properties' ->> 'ignoreMissingVnetServiceEndpoint' as "Ignore Missing VNet Service Endpoint",
      r ->> 'virtualNetworkSubnetId' as "Virtual Network Subnet ID",
      r ->> type as "Type",
      r ->> 'id' as "ID"
    from
      azure_sql_server,
      jsonb_array_elements(virtual_network_rules) as r
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_audit_policy" {
  sql = <<-EOQ
    select
      p ->> 'name' as "Name",
      p -> 'properties' -> 'auditActionsAndGroups' as "Audit Actions And Groups",
      p ->> 'isAzureMonitorTargetEnabled' as "Is Azure Monitor Target Enabled",
      p ->> 'retentionDays' as "Retention Days",
      p ->> 'state' as "State",
      p ->> 'isStorageSecondaryKeyInUse' as "Is Storage Secondary Key In Use",
      p ->> 'storageAccountSubscriptionId' as "Storage Account Subscription ID",
      p ->> type as "Type",
      p ->> 'id' as "ID"
    from
      azure_sql_server,
      jsonb_array_elements(server_audit_policy) as p
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_vulnerability_assessment" {
  sql = <<-EOQ
    select
      a ->> 'name' as "Name",
      a -> 'properties' -> 'recurringScans' -> 'isEnabled' as "Is Enabled",
      a -> 'properties' -> 'recurringScans' -> 'emailSubscriptionAdmins' as "Email Subscription Admins",
      a ->> 'type'  as "Type",
      a ->> 'id' as "ID"
    from
      azure_sql_server,
      jsonb_array_elements(server_vulnerability_assessment) as a
    where
      id = $1;
  EOQ

  param "id" {}
}

query "azure_sql_server_private_endpoint_connection" {
  sql = <<-EOQ
    select
      c ->> 'PrivateEndpointConnectionName' as "Private Endpoint Connection Name",
      c ->> 'PrivateEndpointConnectionType' as "Private Endpoint Connection Type",
      c ->> 'PrivateEndpointId' as "Private Endpoint ID",
      c ->> 'PrivateLinkServiceConnectionStateActionsRequired' as "Private Link Service Connection State Actions Required",
      c ->> 'PrivateLinkServiceConnectionStateDescription' as "Private Link Service Connection State Description",
      c ->> 'PrivateLinkServiceConnectionStateStatus' as "Private Link Service Connection State Status",
      c ->> 'ProvisioningState' as "Provisioning State",
      c ->> 'PrivateEndpointConnectionId' as "Private Endpoint Connection ID"
    from
      azure_sql_server,
      jsonb_array_elements(private_endpoint_connections) as c
    where
      id = $1;
  EOQ

  param "id" {}
}
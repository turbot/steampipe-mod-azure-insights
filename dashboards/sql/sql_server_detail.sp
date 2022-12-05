dashboard "sql_server_detail" {

  title         = "Azure SQL Server Detail"
  documentation = file("./dashboards/sql/docs/sql_server_detail.md")

  tags = merge(local.sql_common_tags, {
    type = "Detail"
  })

  input "sql_server_id" {
    title = "Select a server:"
    query = query.sql_server_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.sql_server_state
      args = {
        id = self.input.sql_server_id.value
      }
    }

    card {
      width = 2
      query = query.sql_server_version
      args = {
        id = self.input.sql_server_id.value
      }
    }

    card {
      width = 2
      query = query.sql_server_auditing_enabled
      args = {
        id = self.input.sql_server_id.value
      }
    }

    card {
      width = 2
      query = query.sql_server_public_network_access
      args = {
        id = self.input.sql_server_id.value
      }
    }

    card {
      width = 2
      query = query.sql_server_ad_authentication_enabled
      args = {
        id = self.input.sql_server_id.value
      }
    }

    card {
      width = 2
      query = query.sql_server_vulnerability_assessment_enabled
      args = {
        id = self.input.sql_server_id.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "network_subnets" {
        sql = <<-EOQ
          select
            lower(id) as subnet_id
          from
            azure_subnet
          where
            lower(id) in (
              select
                lower(jsonb_array_elements(virtual_network_rules) -> 'properties' ->> 'virtualNetworkSubnetId')
              from
                azure_sql_server
              where
                lower(id) = $1
            )
        EOQ

        args = [self.input.sql_server_id.value]
      }

      with "virtual_networks" {
        sql = <<-EOQ
          select
            lower(id) as virtual_networks_id,
            title as title,
            json_build_object(
              'Name', name,
              'Type', type,
              'ID', id,
              'Resource Group', resource_group,
              'Subscription ID', subscription_id,
              'Address Prefixes', jsonb_array_elements_text(address_prefixes),
              'ID', id
            ) as properties
          from
            azure_virtual_network,
            jsonb_array_elements(subnets) as sub
          where
            lower(sub ->> 'id') in (
              select
                lower(vnr -> 'properties' ->> 'virtualNetworkSubnetId')
              from
                azure_sql_server,
                jsonb_array_elements(virtual_network_rules) as vnr
              where
                lower(id) = $1
            );
        EOQ

        args = [self.input.sql_server_id.value]
      }

      with "key_vaults" {
        sql = <<-EOQ
          select
            lower(id) as key_vault_id
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
                lower(id) = $1
                and ep ->> 'kind' = 'azurekeyvault'
            );
        EOQ

        args = [self.input.sql_server_id.value]
      }

      with "key_vault_keys" {
        sql = <<-EOQ
          with attached_keys as (
            select
              split_part(ep ->> 'serverKeyName','_',1) as key_vault_name,
              split_part(ep ->> 'serverKeyName','_',2) as key_vault_key_name
            from
              azure_sql_server,
              jsonb_array_elements(encryption_protector) as ep
            where
              lower(id) = $1
              and ep ->> 'kind' = 'azurekeyvault'
          )
          select
            lower(b.id) as key_vault_key_id,
            b.title as title,
            json_build_object(
              'Name', b.vault_name,
              'Type', b.type,
              'ID', b.id,
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
            left join azure_key_vault_key as b on lower(a.key_vault_key_name) = lower(b.name);
        EOQ

        args = [self.input.sql_server_id.value]
      }

      with "sql_databases" {
        sql = <<-EOQ
          select
            lower(id)as sql_database_id,
            title as title,
            json_build_object(
              'Name', name,
              'Type', type,
              'ID', id,
              'Resource Group', resource_group,
              'Subscription ID', subscription_id,
              'Zone Redundant', zone_redundant,
              'Status', status,
              'ID', id
            ) as properties
          from
            azure_sql_database
          where
            lower(server_name) = lower(split_part($1, '/', 9));
        EOQ

        args = [self.input.sql_server_id.value]
      }

      nodes = [
        node.key_vault_key,
        node.key_vault,
        node.network_private_endpoint,
        node.network_subnet,
        node.network_virtual_network,
        node.sql_database,
        node.sql_server_mssql_elasticpool,
        node.sql_server
      ]

      edges = [
        edge.sql_server_key_vault_to_key_vault_key,
        edge.sql_server_subnet_to_virtual_network,
        edge.sql_server_to_key_vault,
        edge.sql_server_to_mssql_elasticpool,
        edge.sql_server_to_private_endpoint,
        edge.sql_server_to_sql_database,
        edge.sql_server_to_subnet
      ]

      args = {
        id                  = self.input.sql_server_id.value
        key_vault_ids       = with.key_vaults.rows[*].key_vault_id
        key_vault_key_id    = with.key_vault_keys.rows[*].key_vault_key_id
        network_subnet_ids  = with.network_subnets.rows[*].subnet_id
        sql_database_id     = with.sql_databases.rows[*].sql_database_id
        sql_server_ids      = [self.input.sql_server_id.value]
        virtual_network_ids = with.virtual_networks.rows[*].virtual_networks_id
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
        query = query.sql_server_overview
        args = {
          id = self.input.sql_server_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.sql_server_tags
        args = {
          id = self.input.sql_server_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Encryption"
        query = query.sql_server_encryption
        args = {
          id = self.input.sql_server_id.value
        }
      }

      table {
        title = "Virtual Network Rules"
        query = query.sql_server_virtual_network_rules
        args = {
          id = self.input.sql_server_id.value
        }
      }

      table {
        title = "Firewall Rule"
        query = query.sql_server_firewall_rule
        args = {
          id = self.input.sql_server_id.value
        }
      }

    }

  }

  container {
    width = 12

    table {
      title = "Audit Policy"
      query = query.sql_server_audit_policy
      args = {
        id = self.input.sql_server_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Vulnerability Assessment"
      query = query.sql_server_vulnerability_assessment
      args = {
        id = self.input.sql_server_id.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Private Endpoint Details"
      query = query.sql_server_private_endpoint_connection
      args = {
        id = self.input.sql_server_id.value
      }
    }

  }

}

query "sql_server_input" {
  sql = <<-EOQ
    select
      s.title as label,
      lower(s.id) as value,
      json_build_object(
        'subscription', sub.display_name,
        'resource_group', s.resource_group,
        'region', s.region
      ) as tags
    from
      azure_sql_server as s,
      azure_subscription as sub
    where
      lower(s.subscription_id) = lower(s.subscription_id)
    order by
      s.title;
  EOQ
}

query "sql_server_state" {
  sql = <<-EOQ
    select
      'State' as label,
      state as value
    from
      azure_sql_server
    where
      lower(id) = lower($1);
  EOQ

  param "id" {}

}

query "sql_server_version" {
  sql = <<-EOQ
    select
      'Version' as label,
      version as value
    from
      azure_sql_server
    where
      lower(id) = lower($1);
  EOQ

  param "id" {}
}

query "sql_server_auditing_enabled" {
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
      azure_sql_server as s left join sql_server_audit_enabled as a on lower(s.id) = lower(a.id);
  EOQ
}

query "sql_server_public_network_access" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when public_network_access = 'Enabled' then 'Enabled' else 'Disabled' end as value,
      case when public_network_access = 'Enabled' then 'alert' else 'ok' end as type
    from
      azure_sql_server
    where
      lower(id) = lower($1);
  EOQ

  param "id" {}
}

query "sql_server_ad_authentication_enabled" {
  sql = <<-EOQ
    select
      'Azure AD Authentication' as label,
      case when server_azure_ad_administrator is not null then 'Enabled' else 'Disabled' end as value,
      case when server_azure_ad_administrator is not null then 'ok' else 'alert' end as type
    from
      azure_sql_server
    where
      lower(id) = lower($1);
  EOQ

  param "id" {}
}

query "sql_server_vulnerability_assessment_enabled" {
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
      azure_sql_server as s left join sql_server_va as v on lower(s.id) = lower(v.id)
      where lower(s.id) = lower($1);
  EOQ

  param "id" {}
}

node "sql_server_mssql_elasticpool" {
  category = category.mssql_elasticpool

  sql = <<-EOQ
    select
      lower(e.id) as id,
      e.title as title,
      json_build_object(
        'Name', e.name,
        'Type', e.type,
        'ID', e.id,
        'Resource Group', e.resource_group,
        'Subscription ID', e.subscription_id,
        'Edition', e.edition
      ) as properties
    from
      azure_mssql_elasticpool as e
      left join azure_sql_server as s on lower(e.server_name) = lower(s.name)
    where
      lower(s.id) = any($1);;
  EOQ

  param "sql_server_ids" {}
}

edge "sql_server_to_mssql_elasticpool" {
  title = "elastic pool"

  sql = <<-EOQ
    select
      lower(s.id) as from_id,
      lower(e.id) as to_id
    from
      azure_mssql_elasticpool as e
      left join azure_sql_server as s on lower(e.server_name) = lower(s.name)
    where
      lower(s.id) = any($1);;
  EOQ

  param "sql_server_ids" {}
}

query "sql_server_overview" {
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
      lower(id) = lower($1)
  EOQ

  param "id" {}
}

query "sql_server_tags" {
  sql = <<-EOQ
    select
      tag.key as "Key",
      tag.value as "Value"
    from
      azure_sql_server,
      jsonb_each_text(tags) as tag
    where
      lower(id) = lower($1)
    order by
      tag.key;
    EOQ

  param "id" {}
}

query "sql_server_encryption" {
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
      lower(id) = lower($1);
  EOQ

  param "id" {}
}

query "sql_server_virtual_network_rules" {
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
      lower(id) = lower($1);
  EOQ

  param "id" {}
}

query "sql_server_firewall_rule" {
  sql = <<-EOQ
    select
      r ->> 'name' as "Name",
      r -> 'properties' -> 'endIpAddress' as "End IP Address",
      r -> 'properties' -> 'startIpAddress' as "Start IP Address",
      r ->> type as "Type"
    from
      azure_sql_server,
      jsonb_array_elements(firewall_rules) as r
    where
      lower(id) = lower($1);
  EOQ

  param "id" {}
}

query "sql_server_audit_policy" {
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
      lower(id) = lower($1);
  EOQ

  param "id" {}
}

query "sql_server_vulnerability_assessment" {
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
      lower(id) = lower($1);
  EOQ

  param "id" {}
}

query "sql_server_private_endpoint_connection" {
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
      lower(id) = lower($1);
  EOQ

  param "id" {}
}
